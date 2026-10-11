-- =============================================================================
-- SCRIPTS: RPC (functions + grant). Chạy sau schema.sql trong Supabase SQL Editor.
-- =============================================================================

-- ---------- 1. RPC: Đăng nhập bằng username hoặc email ----------
create or replace function coinsort.get_email_for_login(login_id text)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  result text;
begin
  login_id := trim(login_id);
  if login_id = '' then return null; end if;
  if position('@' in login_id) > 0 then return login_id; end if;
  select u.email into result
  from auth.users u
  inner join coinsort.users p on p.id = u.id
  where p.username = login_id
  limit 1;
  if result is null then
    select u.email into result
    from auth.users u
    inner join coinsort.users p on p.id = u.id
    where p.full_name = login_id
    limit 1;
  end if;
  return result;
end;
$$;
grant execute on function coinsort.get_email_for_login(text) to anon;

-- ---------- 2. RPC: Tạo nhóm (insert group + member, trả về group) ----------
create or replace function coinsort.create_group(p_name text)
returns setof coinsort.groups
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  new_id uuid;
begin
  insert into coinsort.groups (name, is_personal, status)
  values (trim(p_name), false, 'active')
  returning id into new_id;
  insert into coinsort.group_members (group_id, user_id, role, status)
  values (new_id, auth.uid(), 'admin', 'active');
  return query select * from coinsort.groups where id = new_id;
end;
$$;
grant execute on function coinsort.create_group(text) to authenticated;

-- ---------- 3. RPC: Tham gia nhóm bằng ID ----------
create or replace function coinsort.join_group(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  g record;
begin
  select id, is_personal into g from coinsort.groups where id = p_group_id and status = 'active';
  if not found then return 'Không tìm thấy nhóm'; end if;
  if g.is_personal then return 'Không thể tham gia nhóm cá nhân'; end if;
  insert into coinsort.group_members (group_id, user_id, role, status)
  values (p_group_id, auth.uid(), 'member', 'active');
  return '';
exception
  when unique_violation then return 'Bạn đã ở trong nhóm này';
end;
$$;
grant execute on function coinsort.join_group(uuid) to authenticated;

-- ---------- 4. RPC: Danh sách nhóm user tham gia ----------
create or replace function coinsort.get_user_groups()
returns setof coinsort.groups
language sql
security definer
set search_path = coinsort, public, extensions
stable
as $$
  select g.* from coinsort.groups g
  inner join coinsort.group_members gm on gm.group_id = g.id and gm.user_id = auth.uid() and gm.status = 'active'
  where g.status = 'active';
$$;
grant execute on function coinsort.get_user_groups() to authenticated;

-- ---------- 5. RPC: Thành viên nhóm (chỉ khi user đã ở trong nhóm), trả về json ----------
create or replace function coinsort.get_group_members(p_group_id uuid)
returns json
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
declare
  result json;
begin
  if not exists (select 1 from coinsort.group_members gm where gm.group_id = p_group_id and gm.user_id = auth.uid() and gm.status = 'active') then
    return '[]'::json;
  end if;
  select coalesce(json_agg(row_to_json(t)), '[]'::json) into result
  from (
    select
      gm.id,
      gm.group_id,
      gm.user_id,
      gm.role,
      gm.status,
      gm.joined_at,
      json_build_object('id', u.id, 'username', u.username, 'full_name', u.full_name, 'avatar_url', u.avatar_url) as "user"
    from coinsort.group_members gm
    join coinsort.users u on u.id = gm.user_id
    where gm.group_id = p_group_id and gm.status = 'active'
  ) t;
  return result;
end;
$$;
grant execute on function coinsort.get_group_members(uuid) to authenticated;

-- ---------- 6. RPC: Tìm user theo username/full_name (để mời vào nhóm) ----------
drop function if exists coinsort.search_users(text);
create or replace function coinsort.search_users(p_query text)
returns table(id uuid, username text, full_name text, avatar_url text)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
declare
  q text;
begin
  q := trim(p_query);
  if length(q) < 2 then
    return;
  end if;
  q := '%' || replace(replace(q, '\', '\\'), '%', '\%') || '%';
  return query
  select u.id, u.username, u.full_name, u.avatar_url
  from coinsort.users u
  where u.status = 'active'
    and u.id != auth.uid()
    and (u.username ilike q escape '\' or u.full_name ilike q escape '\')
  order by u.username nulls last, u.full_name nulls last
  limit 30;
end;
$$;
grant execute on function coinsort.search_users(text) to authenticated;

-- ---------- 7. RPC: Mời user vào nhóm (tạo lời mời pending) ----------
drop function if exists coinsort.invite_to_group(uuid, uuid);
create or replace function coinsort.invite_to_group(p_group_id uuid, p_user_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  g record;
begin
  if p_group_id is null or p_user_id is null then
    return 'Thiếu thông tin nhóm hoặc người được mời';
  end if;
  if p_user_id = auth.uid() then
    return 'Không thể mời chính mình';
  end if;
  select id, is_personal into g from coinsort.groups where id = p_group_id and status = 'active';
  if not found then return 'Không tìm thấy nhóm'; end if;
  if g.is_personal then return 'Không thể mời vào nhóm cá nhân'; end if;
  if not exists (select 1 from coinsort.group_members gm where gm.group_id = p_group_id and gm.user_id = auth.uid() and gm.role = 'admin' and gm.status = 'active') then
    return 'Chỉ admin nhóm mới mời được thành viên';
  end if;
  if not exists (select 1 from coinsort.users where id = p_user_id and status = 'active') then
    return 'Người dùng không tồn tại hoặc đã bị vô hiệu hóa';
  end if;
  if exists (select 1 from coinsort.group_members gm where gm.group_id = p_group_id and gm.user_id = p_user_id and gm.status = 'active') then
    return 'Người này đã ở trong nhóm';
  end if;
  insert into coinsort.group_invitations (group_id, user_id, invited_by, status)
  values (p_group_id, p_user_id, auth.uid(), 'pending');
  return '';
exception
  when unique_violation then return 'Đã gửi lời mời rồi';
end;
$$;
grant execute on function coinsort.invite_to_group(uuid, uuid) to authenticated;

-- ---------- 8. RPC: Danh sách lời mời của tôi ----------
create or replace function coinsort.get_my_invitations()
returns table (id uuid, group_id uuid, group_name text, invited_by uuid, inviter_name text, created_at timestamptz)
language sql
security definer
set search_path = coinsort, public, extensions
stable
as $$
  select i.id, i.group_id, g.name, i.invited_by, coalesce(u.full_name, u.username, '')::text, i.created_at
  from coinsort.group_invitations i
  join coinsort.groups g on g.id = i.group_id
  join coinsort.users u on u.id = i.invited_by
  where i.user_id = auth.uid() and i.status = 'pending';
$$;
grant execute on function coinsort.get_my_invitations() to authenticated;

-- ---------- 9. RPC: Chấp nhận lời mời ----------
create or replace function coinsort.accept_invitation(p_invitation_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  inv record;
begin
  select i.id, i.group_id, i.user_id into inv
  from coinsort.group_invitations i
  where i.id = p_invitation_id and i.user_id = auth.uid() and i.status = 'pending';
  if not found then return 'Lời mời không tồn tại hoặc đã xử lý'; end if;
  insert into coinsort.group_members (group_id, user_id, role, status)
  values (inv.group_id, inv.user_id, 'member', 'active');
  update coinsort.group_invitations set status = 'accepted' where id = p_invitation_id;
  return '';
exception
  when unique_violation then return 'Bạn đã ở trong nhóm này';
end;
$$;
grant execute on function coinsort.accept_invitation(uuid) to authenticated;

-- ---------- 10. RPC: Từ chối lời mời ----------
create or replace function coinsort.decline_invitation(p_invitation_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  update coinsort.group_invitations
  set status = 'declined'
  where id = p_invitation_id and user_id = auth.uid() and status = 'pending';
  if not FOUND then return 'Lời mời không tồn tại hoặc đã xử lý'; end if;
  return '';
end;
$$;
grant execute on function coinsort.decline_invitation(uuid) to authenticated;

-- ---------- 11. RPC: Rời nhóm ----------
create or replace function coinsort.leave_group(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  g record;
begin
  select id, is_personal into g from coinsort.groups where id = p_group_id and status = 'active';
  if not found then return 'Nhóm không tồn tại'; end if;
  if g.is_personal then return 'Không thể rời nhóm cá nhân'; end if;
  update coinsort.group_members
  set status = 'left'
  where group_id = p_group_id and user_id = auth.uid() and status = 'active';
  if not FOUND then return 'Bạn không ở trong nhóm này'; end if;
  return '';
end;
$$;
grant execute on function coinsort.leave_group(uuid) to authenticated;

-- ---------- 12. RPC: Kick thành viên khỏi nhóm (chỉ admin) ----------
create or replace function coinsort.kick_member(p_group_id uuid, p_user_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  admin_count int;
begin
  if p_user_id = auth.uid() then return 'Không thể kick chính mình'; end if;
  if not exists (select 1 from coinsort.group_members gm where gm.group_id = p_group_id and gm.user_id = auth.uid() and gm.role = 'admin' and gm.status = 'active') then
    return 'Chỉ admin nhóm mới được kick thành viên';
  end if;
  select count(*) into admin_count from coinsort.group_members where group_id = p_group_id and role = 'admin' and status = 'active';
  if admin_count <= 1 and exists (select 1 from coinsort.group_members where group_id = p_group_id and user_id = p_user_id and role = 'admin' and status = 'active') then
    return 'Không thể kick admin cuối cùng của nhóm';
  end if;
  update coinsort.group_members
  set status = 'left'
  where group_id = p_group_id and user_id = p_user_id and status = 'active';
  if not FOUND then return 'Thành viên không tồn tại trong nhóm'; end if;
  return '';
end;
$$;
grant execute on function coinsort.kick_member(uuid, uuid) to authenticated;

-- ---------- 13. RPC: Xoá mềm giao dịch (set row_status = 'deleted') ----------
-- SECURITY DEFINER để tránh 403; kiểm tra user là thành viên nhóm trước khi update.
create or replace function coinsort.soft_delete_transaction(p_transaction_id uuid, p_group_id uuid)
returns boolean
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  n int;
begin
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = auth.uid() and gm.status = 'active'
  ) then
    return false;
  end if;
  update coinsort.transactions
  set row_status = 'deleted'
  where id = p_transaction_id and group_id = p_group_id
    and (row_status is null or row_status = 'active');
  get diagnostics n = row_count;
  return n > 0;
end;
$$;
grant execute on function coinsort.soft_delete_transaction(uuid, uuid) to authenticated;
grant execute on function coinsort.soft_delete_transaction(uuid, uuid) to service_role;
