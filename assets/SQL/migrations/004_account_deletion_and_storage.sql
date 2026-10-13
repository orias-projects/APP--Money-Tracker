-- =============================================================================
-- MIGRATION 004 — Xoá tài khoản và Storage (Giai đoạn 4)
--
-- Chạy SAU 003. Idempotent.
--
-- Google Play và App Store đều BẮT BUỘC app có luồng cho người dùng tự xoá
-- tài khoản ngay trong app. Đây là phần server của luồng đó.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Xoá tài khoản
-- ---------------------------------------------------------------------------
-- Chiến lược: xoá mềm hồ sơ + rời mọi nhóm chung + ẩn dữ liệu cá nhân.
-- KHÔNG xoá cứng giao dịch trong nhóm chung, vì làm vậy sẽ phá công nợ của
-- những thành viên còn lại. Giao dịch giữ lại nhưng không còn gắn với hồ sơ.
create or replace function coinsort.delete_my_account(p_confirm text)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_personal_group uuid;
begin
  if v_uid is null then return 'Chưa đăng nhập'; end if;

  -- Yêu cầu gõ đúng chữ để tránh xoá nhầm.
  if upper(trim(coalesce(p_confirm, ''))) <> 'XOA TAI KHOAN' then
    return 'Chưa xác nhận đúng';
  end if;

  -- 1. Rời mọi nhóm chung (giữ lại giao dịch để nhóm không thủng sổ)
  update coinsort.group_members gm
     set status = 'left'
   where gm.user_id = v_uid
     and gm.status = 'active'
     and exists (
       select 1 from coinsort.groups g
       where g.id = gm.group_id and g.is_personal = false
     );

  -- 2. Xoá nhóm cá nhân và toàn bộ dữ liệu trong đó
  select g.id into v_personal_group
  from coinsort.groups g
  join coinsort.group_members gm on gm.group_id = g.id
  where gm.user_id = v_uid and g.is_personal = true
  limit 1;

  if v_personal_group is not null then
    delete from coinsort.transactions where group_id = v_personal_group;
    delete from coinsort.groups where id = v_personal_group;
  end if;

  -- 3. Dữ liệu chỉ thuộc về cá nhân
  delete from coinsort.budgets                where user_id = v_uid;
  delete from coinsort.recurring_transactions where user_id = v_uid;
  delete from coinsort.debts_loans            where user_id = v_uid;
  delete from coinsort.tags                   where user_id = v_uid;
  delete from coinsort.categories             where user_id = v_uid;
  delete from coinsort.group_invitations      where user_id = v_uid or invited_by = v_uid;

  -- 4. Ví: chỉ xoá ví chưa từng dùng; ví đã có giao dịch thì ẩn đi
  delete from coinsort.accounts a
   where a.user_id = v_uid
     and not exists (
       select 1 from coinsort.transactions t
       where t.account_id = a.id or t.to_account_id = a.id
     );
  update coinsort.accounts set status = 'deleted', name = 'Ví đã xoá'
   where user_id = v_uid;

  -- 5. Ẩn hồ sơ
  update coinsort.users
     set status = 'deleted',
         full_name = 'Người dùng đã xoá',
         username = 'deleted_' || left(v_uid::text, 8),
         avatar_url = null
   where id = v_uid;

  -- 6. Xoá tài khoản đăng nhập. Nếu không đủ quyền thì hồ sơ vẫn đã bị vô hiệu.
  begin
    delete from auth.users where id = v_uid;
  exception when others then
    null;
  end;

  return '';
end;
$$;
grant execute on function coinsort.delete_my_account(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Ẩn người dùng đã xoá khỏi tìm kiếm và danh sách thành viên
-- ---------------------------------------------------------------------------
-- search_users đã lọc status = 'active' từ migration 002.

-- ---------------------------------------------------------------------------
-- 3. Storage — ảnh hoá đơn và ảnh đại diện
-- ---------------------------------------------------------------------------
-- Tạo bucket trước trong Dashboard → Storage:
--   receipts : KHÔNG public
--   avatars  : public
-- Rồi chạy phần policy dưới đây.

insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Ảnh hoá đơn: mỗi người chỉ đọc/ghi thư mục mang UID của mình.
drop policy if exists "Users manage own receipts" on storage.objects;
create policy "Users manage own receipts"
  on storage.objects for all
  to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Ảnh đại diện: ai cũng xem được, chỉ chủ mới ghi đè.
drop policy if exists "Avatars are publicly readable" on storage.objects;
create policy "Avatars are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Users manage own avatar" on storage.objects;
create policy "Users manage own avatar"
  on storage.objects for all
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- 4. Cập nhật ảnh đại diện
-- ---------------------------------------------------------------------------
create or replace function coinsort.update_my_avatar(p_url text)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  if auth.uid() is null then return 'Chưa đăng nhập'; end if;
  update coinsort.users set avatar_url = p_url where id = auth.uid();
  return '';
end;
$$;
grant execute on function coinsort.update_my_avatar(text) to authenticated;
