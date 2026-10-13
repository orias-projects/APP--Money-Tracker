-- =============================================================================
-- MIGRATION 006 — Vá lỗ hổng P0-4: xoá tài khoản an toàn (GDPR / App Store)
--
-- Chạy SAU 005. Idempotent (create or replace + grant + bọc trong begin/commit).
-- KHÔNG sửa 001-005, schema.sql, scripts.sql — chỉ create-or-replace lại hàm
-- coinsort.delete_my_account(p_confirm text), giữ nguyên chữ ký, chuỗi xác nhận
-- 'XOA TAI KHOAN' và hợp đồng trả về ('' = thành công).
--
-- -----------------------------------------------------------------------------
-- BỐI CẢNH LỖ HỔNG (hàm cũ ở migration 004)
-- -----------------------------------------------------------------------------
-- Bước cuối của 004 là `delete from auth.users where id = v_uid`, bọc trong
-- `exception when others then null`. Xét chuỗi khoá ngoại thật trong schema.sql:
--
--   auth.users --(users.id on delete CASCADE)-->
--   coinsort.users --(accounts.user_id on delete CASCADE)-->
--   coinsort.accounts --(transactions.account_id / to_account_id on delete CASCADE)-->
--   coinsort.transactions --(transaction_splits.transaction_id on delete CASCADE)-->
--   coinsort.transaction_splits
--
-- => Hard-delete auth.users sẽ XOÁ CỨNG cả giao dịch trong NHÓM CHUNG dùng ví
--    do người này sở hữu, kéo theo transaction_splits. Sổ nhóm mất cân, công nợ
--    của thành viên khác bị thủng, verify_balances.sql sẽ đỏ.
--
-- Tệ hơn: transactions.created_by và transactions.paid_by khai báo
--    `references coinsort.users(id) on delete SET NULL` NHƯNG cột lại là NOT NULL.
--    Với giao dịch của NGƯỜI KHÁC trong nhóm chung mà người này từng tạo/đứng
--    trả, cascade sẽ cố SET NULL vào cột NOT NULL -> vi phạm ràng buộc -> LỆNH
--    delete auth.users NÉM LỖI. Vì 004 nuốt lỗi (`when others then null`), hàm
--    vẫn trả '' (thành công) trong khi tài khoản auth.users còn nguyên và người
--    dùng vẫn đăng nhập được. Đây chính là "báo thành công giả".
--
-- -----------------------------------------------------------------------------
-- CHIẾN LƯỢC ĐÃ CHỌN: ANONYMISE + BAN (KHÔNG hard-delete auth.users)
-- -----------------------------------------------------------------------------
-- Theo phương án ưu tiên trong yêu cầu: KHÔNG `delete from auth.users` trong hàm
-- này. Thay vào đó:
--   (1) Ẩn/anonymise hồ sơ trong coinsort.users (status='deleted', đổi tên,
--       đổi username, xoá avatar) — như 004.
--   (2) VÔ HIỆU HOÁ ĐĂNG NHẬP ngay trên auth.users bằng `banned_until` đặt vào
--       tương lai rất xa (khoá vĩnh viễn), đồng thời xoá mật khẩu băm và dọn
--       metadata OAuth chứa PII. KHÔNG xoá row auth.users -> KHÔNG kích hoạt
--       cascade -> giao dịch & split của nhóm chung được GIỮ NGUYÊN.
--
-- Vì sao ban thay vì hard-delete (tóm tắt hệ quả):
--   - Giữ row coinsort.users (đã ẩn) => accounts/transactions/splits/settlements
--     của nhóm chung không bị cascade xoá; công nợ người khác không thủng.
--   - Tránh hẳn lỗi NOT NULL của created_by/paid_by nêu trên.
--   - Sau khi ban: người dùng KHÔNG đăng nhập lại được; dữ liệu cá nhân đã ẩn
--     và đã dọn; dữ liệu nhóm chung giữ lại để bảo toàn tính toàn vẹn sổ nhóm.
--
-- Vì sao KHÔNG chọn hard-delete-có-gỡ-liên-kết: transactions.account_id là
-- NOT NULL + CASCADE, muốn hard-delete phải chuyển account_id của mọi giao dịch
-- nhóm chung sang một ví "tombstone" giữ lại rồi mới xoá — rủi ro cao (đụng
-- trigger số dư, đụng RLS, dễ sai số dư ví nhóm). Phương án ban đạt cùng mục tiêu
-- tuân thủ (không đăng nhập lại được + xoá dữ liệu cá nhân) với rủi ro thấp hơn
-- nhiều, nên là mặc định.
-- =============================================================================

begin;

create or replace function coinsort.delete_my_account(p_confirm text)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_uid            uuid := auth.uid();
  v_personal_group uuid;
  v_group          record;
  v_promote_member uuid;
  v_banned_until   timestamptz := now() + interval '1000 years'; -- khoá vĩnh viễn
begin
  if v_uid is null then return 'Chưa đăng nhập'; end if;

  -- Yêu cầu gõ đúng chữ để tránh xoá nhầm.
  if upper(trim(coalesce(p_confirm, ''))) <> 'XOA TAI KHOAN' then
    return 'Chưa xác nhận đúng';
  end if;

  -- ---------------------------------------------------------------------------
  -- D. ADMIN CUỐI CÙNG — chuyển quyền trước khi rời các NHÓM CHUNG
  -- ---------------------------------------------------------------------------
  -- Với mỗi nhóm chung (is_personal=false) mà người này đang là admin: nếu nhóm
  -- KHÔNG còn admin active nào khác thì trao quyền admin cho một thành viên
  -- active khác cũ nhất (joined_at nhỏ nhất). Nếu không còn thành viên active
  -- nào khác thì để nhóm lại như cũ (nhóm rỗng, không còn ai để trao) — chấp
  -- nhận được vì không còn người bị kẹt vì mất admin.
  for v_group in
    select gm.group_id
      from coinsort.group_members gm
      join coinsort.groups g on g.id = gm.group_id
     where gm.user_id = v_uid
       and gm.status  = 'active'
       and gm.role    = 'admin'
       and g.is_personal = false
  loop
    if not exists (
      select 1
        from coinsort.group_members gm2
       where gm2.group_id = v_group.group_id
         and gm2.user_id <> v_uid
         and gm2.status  = 'active'
         and gm2.role    = 'admin'
    ) then
      select gm3.user_id
        into v_promote_member
        from coinsort.group_members gm3
       where gm3.group_id = v_group.group_id
         and gm3.user_id <> v_uid
         and gm3.status  = 'active'
       order by gm3.joined_at asc
       limit 1;

      if v_promote_member is not null then
        update coinsort.group_members
           set role = 'admin'
         where group_id = v_group.group_id
           and user_id  = v_promote_member;
      end if;
    end if;
  end loop;

  -- ---------------------------------------------------------------------------
  -- A. Rời mọi NHÓM CHUNG (giữ lại giao dịch/split để nhóm không thủng sổ)
  -- ---------------------------------------------------------------------------
  update coinsort.group_members gm
     set status = 'left'
   where gm.user_id = v_uid
     and gm.status  = 'active'
     and exists (
       select 1 from coinsort.groups g
       where g.id = gm.group_id and g.is_personal = false
     );

  -- ---------------------------------------------------------------------------
  -- Xoá nhóm CÁ NHÂN và toàn bộ dữ liệu trong đó (không ảnh hưởng ai khác)
  -- ---------------------------------------------------------------------------
  select g.id into v_personal_group
  from coinsort.groups g
  join coinsort.group_members gm on gm.group_id = g.id
  where gm.user_id = v_uid and g.is_personal = true
  limit 1;

  if v_personal_group is not null then
    -- Xoá giao dịch cá nhân trước (trigger đảo số dư ví cá nhân), rồi xoá nhóm.
    delete from coinsort.transactions where group_id = v_personal_group;
    delete from coinsort.groups where id = v_personal_group;
  end if;

  -- ---------------------------------------------------------------------------
  -- E. Dọn dữ liệu CHỈ thuộc về cá nhân (giữ nguyên như 004)
  -- ---------------------------------------------------------------------------
  delete from coinsort.budgets                where user_id = v_uid;
  delete from coinsort.recurring_transactions where user_id = v_uid;
  delete from coinsort.debts_loans            where user_id = v_uid;
  delete from coinsort.tags                   where user_id = v_uid;
  delete from coinsort.categories             where user_id = v_uid;
  delete from coinsort.group_invitations      where user_id = v_uid or invited_by = v_uid;

  -- Ví CÁ NHÂN (group_id is null): ví chưa từng dùng thì xoá hẳn; ví đã có giao
  -- dịch thì ẩn đi. CHỦ Ý chỉ đụng ví cá nhân — KHÔNG đụng ví dùng chung của
  -- nhóm (group_id is not null) để không phá ledger nhóm còn thành viên khác.
  delete from coinsort.accounts a
   where a.user_id = v_uid
     and a.group_id is null
     and not exists (
       select 1 from coinsort.transactions t
       where t.account_id = a.id or t.to_account_id = a.id
     );
  update coinsort.accounts
     set status = 'deleted', name = 'Ví đã xoá'
   where user_id = v_uid
     and group_id is null;

  -- ---------------------------------------------------------------------------
  -- C. Xoá STORAGE — ảnh hoá đơn (bucket receipts) và avatar (bucket avatars)
  -- ---------------------------------------------------------------------------
  -- App lưu theo path '{uid}/...'; policy ở 004 khớp bằng
  -- (storage.foldername(name))[1] = auth.uid()::text, nên lấy uid từ path y hệt.
  -- Lưu ý: xoá TẤT CẢ file dưới thư mục của người này (kể cả ảnh hoá đơn từng
  -- gắn vào giao dịch nhóm chung được giữ lại) vì đó là dữ liệu do người này
  -- upload — đúng yêu cầu GDPR. transactions.image_url tương ứng sẽ trỏ tới file
  -- không còn tồn tại; app phải chịu được ảnh thiếu (xem ghi chú rủi ro cuối file).
  delete from storage.objects
   where bucket_id = 'receipts'
     and (storage.foldername(name))[1] = v_uid::text;

  delete from storage.objects
   where bucket_id = 'avatars'
     and (storage.foldername(name))[1] = v_uid::text;

  -- ---------------------------------------------------------------------------
  -- Ẩn / anonymise hồ sơ công khai (giữ nguyên như 004)
  -- ---------------------------------------------------------------------------
  update coinsort.users
     set status     = 'deleted',
         full_name  = 'Người dùng đã xoá',
         username   = 'deleted_' || left(v_uid::text, 8),
         avatar_url = null
   where id = v_uid;

  -- ---------------------------------------------------------------------------
  -- B. VÔ HIỆU HOÁ ĐĂNG NHẬP — KHÔNG nuốt lỗi, KHÔNG hard-delete auth.users
  -- ---------------------------------------------------------------------------
  -- Ban vĩnh viễn (banned_until ở tương lai rất xa) => GoTrue chặn cấp/refresh
  -- token. Xoá luôn mật khẩu băm (PII/credential) và dọn raw_user_meta_data
  -- (chứa full_name/avatar từ OAuth) để không giữ lại PII. GIỮ raw_app_meta_data
  -- (thông tin provider) để GoTrue không rối. KHÔNG dùng literal 'infinity' cho
  -- banned_until vì một số phiên bản driver Go của GoTrue scan 'infinity' vào
  -- time.Time không ổn định — dùng mốc hữu hạn 1000 năm cho chắc.
  update auth.users
     set banned_until        = v_banned_until,
         encrypted_password  = null,
         raw_user_meta_data  = '{}'::jsonb,
         updated_at          = now()
   where id = v_uid;

  -- Nếu không cập nhật được row auth.users (thiếu quyền / không tìm thấy) thì
  -- KHÔNG được coi là thành công: ném lỗi để toàn bộ transaction rollback và
  -- client biết là thất bại (thay cho hành vi nuốt lỗi cũ ở 004).
  if not found then
    raise exception 'delete_my_account: không vô hiệu hoá được đăng nhập (auth.users id=%).', v_uid;
  end if;

  -- Thu hồi phiên đang mở để buộc đăng xuất sớm (refresh token bị vô hiệu qua
  -- cascade session_id). Bảo vệ HẸP: chỉ bỏ qua nếu phiên bản GoTrue cũ không có
  -- bảng/cột này (undefined_table/undefined_column) — mọi lỗi khác vẫn nổi lên.
  -- Đây KHÔNG phải kiểu nuốt lỗi bao trùm `when others` của 004.
  begin
    delete from auth.sessions where user_id = v_uid;
  exception
    when undefined_table or undefined_column then
      null;
  end;

  return '';
end;
$$;

grant execute on function coinsort.delete_my_account(text) to authenticated;

commit;
