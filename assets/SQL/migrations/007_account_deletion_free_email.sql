-- =============================================================================
-- MIGRATION 007 — Xoá tài khoản phải GIẢI PHÓNG EMAIL (vá tiếp 006)
--
-- Chạy SAU 006. Idempotent (create or replace + grant + bọc trong begin/commit).
--
-- -----------------------------------------------------------------------------
-- LỖ HỔNG CÒN LẠI CỦA 006
-- -----------------------------------------------------------------------------
-- 006 ban vĩnh viễn auth.users và xoá mật khẩu/metadata, nhưng GIỮ NGUYÊN cột
-- email. Hệ quả:
--   (1) Email — một PII — bị lưu VĨNH VIỄN, trái với cam kết trong màn Quyền
--       riêng tư ("hồ sơ, dữ liệu cá nhân... sẽ bị xoá"). Google Play Data
--       safety review so khai báo với hành vi thật.
--   (2) Ràng buộc unique trên email + ban vĩnh viễn => người dùng KHÔNG BAO GIỜ
--       đăng ký lại được bằng chính email của mình. Không có code nào gỡ ban.
--
-- CÁCH VÁ: sau khi ban, đổi email thành tombstone không trùng và không phải
-- email thật ('deleted+<uuid8>@deleted.invalid'), xoá email/phone khỏi
-- auth.identities (identity_data chứa bản sao email), nhờ đó:
--   - PII email không còn trong hệ thống.
--   - Email thật được tự do để đăng ký tài khoản mới.
-- Row auth.users vẫn GIỮ (không cascade) — đúng chiến lược của 006.
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

  -- Yêu cầu gõ đúng chữ để tránh xoá nhầm. Client LUÔN gửi cụm chuẩn này
  -- (UI đối chiếu cụm theo ngôn ngữ hiển thị trước khi gọi RPC).
  if upper(trim(coalesce(p_confirm, ''))) <> 'XOA TAI KHOAN' then
    return 'Chưa xác nhận đúng';
  end if;

  -- ---------------------------------------------------------------------------
  -- D. ADMIN CUỐI CÙNG — chuyển quyền trước khi rời các NHÓM CHUNG (như 006)
  -- ---------------------------------------------------------------------------
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
  -- Xoá nhóm CÁ NHÂN và toàn bộ dữ liệu trong đó (như 006)
  -- ---------------------------------------------------------------------------
  select g.id into v_personal_group
  from coinsort.groups g
  join coinsort.group_members gm on gm.group_id = g.id
  where gm.user_id = v_uid and g.is_personal = true
  limit 1;

  if v_personal_group is not null then
    delete from coinsort.transactions where group_id = v_personal_group;
    delete from coinsort.groups where id = v_personal_group;
  end if;

  -- ---------------------------------------------------------------------------
  -- E. Dọn dữ liệu CHỈ thuộc về cá nhân (như 006)
  -- ---------------------------------------------------------------------------
  delete from coinsort.budgets                where user_id = v_uid;
  delete from coinsort.recurring_transactions where user_id = v_uid;
  delete from coinsort.debts_loans            where user_id = v_uid;
  delete from coinsort.tags                   where user_id = v_uid;
  delete from coinsort.categories             where user_id = v_uid;
  delete from coinsort.group_invitations      where user_id = v_uid or invited_by = v_uid;

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
  -- C. Xoá STORAGE — ảnh hoá đơn và avatar (như 006)
  -- ---------------------------------------------------------------------------
  delete from storage.objects
   where bucket_id = 'receipts'
     and (storage.foldername(name))[1] = v_uid::text;

  delete from storage.objects
   where bucket_id = 'avatars'
     and (storage.foldername(name))[1] = v_uid::text;

  -- ---------------------------------------------------------------------------
  -- Ẩn / anonymise hồ sơ công khai (như 006)
  -- ---------------------------------------------------------------------------
  update coinsort.users
     set status     = 'deleted',
         full_name  = 'Người dùng đã xoá',
         username   = 'deleted_' || left(v_uid::text, 8),
         avatar_url = null
   where id = v_uid;

  -- ---------------------------------------------------------------------------
  -- B. VÔ HIỆU HOÁ ĐĂNG NHẬP + GIẢI PHÓNG EMAIL (điểm mới của 007)
  -- ---------------------------------------------------------------------------
  -- Như 006 (ban vĩnh viễn, xoá mật khẩu, dọn metadata) VÀ thay email bằng
  -- tombstone: PII biến mất, unique-constraint được nhả ra để người dùng có thể
  -- đăng ký lại bằng email cũ. Đuôi '.invalid' là TLD dành riêng (RFC 2606) —
  -- không bao giờ gửi thư nhầm được.
  update auth.users
     set banned_until        = v_banned_until,
         encrypted_password  = null,
         raw_user_meta_data  = '{}'::jsonb,
         email               = 'deleted+' || left(v_uid::text, 8) || '@deleted.invalid',
         email_change        = '',
         phone               = null,
         updated_at          = now()
   where id = v_uid;

  if not found then
    raise exception 'delete_my_account: không vô hiệu hoá được đăng nhập (auth.users id=%).', v_uid;
  end if;

  -- Bản sao email còn nằm trong auth.identities (identity_data->>'email').
  -- Tài khoản đã ban vĩnh viễn thì identities không còn tác dụng — xoá hẳn.
  -- Bảo vệ HẸP như 006: chỉ bỏ qua nếu phiên bản GoTrue không có bảng này.
  begin
    delete from auth.identities where user_id = v_uid;
  exception
    when undefined_table or undefined_column then
      null;
  end;

  -- Thu hồi phiên đang mở (như 006).
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
