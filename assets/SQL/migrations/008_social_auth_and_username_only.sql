-- =============================================================================
-- MIGRATION 008 — Đăng nhập mạng xã hội, đăng ký username-only, gợi ý bạn bè
--
-- Chạy SAU 007. Idempotent.
--
-- Bối cảnh (docs/SOCIAL_AUTH_SETUP.md, phụ lục ràng buộc kỹ thuật):
--   * Đăng ký chỉ cần username + mật khẩu. GoTrue bắt buộc email nên client
--     tạo email TỔNG HỢP `<username>@noemail.coinsort.app` — không bao giờ
--     gửi thư tới đó. Khi người dùng thêm email thật, client gọi
--     auth.updateUser(email) → GoTrue gửi link xác minh tới email mới.
--   * Đăng nhập Google/Facebook/X: GoTrue tạo auth.users + identities; trigger
--     handle_new_user tạo hồ sơ. Username và mật khẩu ĐỂ TRỐNG cho tới khi
--     người dùng tự đặt trong màn Tài khoản.
--   * Bạn bè Facebook: client lấy danh sách bạn (chỉ bạn cũng dùng app) qua
--     Graph API rồi đồng bộ vào social_friends; get_friend_suggestions khớp
--     với auth.identities để gợi ý người mời vào nhóm.
--
-- Cấu hình Dashboard bắt buộc đi kèm (xem docs/SOCIAL_AUTH_SETUP.md):
--   Authentication → Sign In / Up: bật Google, Facebook, Twitter;
--     provider Email: "Confirm email" = OFF, "Secure email change" = OFF;
--     khối User Signups: "Allow manual linking" = ON.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. handle_new_user: username có thể NULL; đọc thêm khoá của provider
-- -----------------------------------------------------------------------------
-- Google trả `full_name`/`name`/`picture`/`avatar_url`; Facebook trả `name`;
-- Twitter trả `full_name`/`user_name`. Trước đây username luôn bị gán
-- 'user_<8 ký tự>' — với người đăng nhập ngoài, yêu cầu mới là ĐỂ TRỐNG.
create or replace function coinsort.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  personal_group_id uuid;
  v_username text;
begin
  v_username := nullif(trim(coalesce(new.raw_user_meta_data->>'username', '')), '');

  insert into coinsort.users (id, full_name, avatar_url, username, role, status)
  values (
    new.id,
    coalesce(
      nullif(trim(coalesce(new.raw_user_meta_data->>'full_name', '')), ''),
      nullif(trim(coalesce(new.raw_user_meta_data->>'name', '')), '')
    ),
    coalesce(
      nullif(new.raw_user_meta_data->>'avatar_url', ''),
      nullif(new.raw_user_meta_data->>'picture', '')
    ),
    v_username,
    'user',
    'active'
  );

  insert into coinsort.groups (name, is_personal, status)
  values ('Chi tiêu cá nhân', true, 'active')
  returning id into personal_group_id;

  insert into coinsort.group_members (group_id, user_id, role, status)
  values (personal_group_id, new.id, 'admin', 'active');

  insert into coinsort.accounts (user_id, name, account_type, balance, opening_balance, currency, status)
  values
    (new.id, 'Tiền mặt', 'asset', 0, 0, 'VND', 'active'),
    (new.id, 'Tài khoản Ngân hàng', 'asset', 0, 0, 'VND', 'active');

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure coinsort.handle_new_user();

-- -----------------------------------------------------------------------------
-- 2. Username không phân biệt hoa/thường
-- -----------------------------------------------------------------------------
-- Dữ liệu cũ có thể đã trùng khi bỏ qua hoa/thường → thử tạo index, nếu vỡ
-- thì chỉ cảnh báo để migration không dừng; chủ dự án dọn tay rồi chạy lại.
do $$
begin
  create unique index if not exists users_username_lower_key
    on coinsort.users (lower(username))
    where username is not null;
exception when unique_violation then
  raise notice '008: username trùng nhau khi bỏ hoa/thường — dọn dữ liệu rồi chạy lại để tạo users_username_lower_key.';
end;
$$;

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

  -- Người dùng nhập sẵn email → trả lại nguyên văn, không tra bảng.
  if position('@' in login_id) > 0 then return login_id; end if;

  select u.email into result
  from auth.users u
  inner join coinsort.users p on p.id = u.id
  where lower(p.username) = lower(login_id)
    and coalesce(p.status, 'active') = 'active'
  limit 1;

  return result;
end;
$$;
grant execute on function coinsort.get_email_for_login(text) to anon;
grant execute on function coinsort.get_email_for_login(text) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Đặt / đổi username (validate + unique phía máy chủ)
-- -----------------------------------------------------------------------------
-- Ném exception với mã ngắn để client dịch: USERNAME_INVALID, USERNAME_TAKEN.
create or replace function coinsort.update_my_username(p_username text)
returns void
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_name text;
begin
  if v_uid is null then
    raise exception 'NOT_LOGGED_IN';
  end if;

  v_name := lower(trim(coalesce(p_username, '')));
  if v_name !~ '^[a-z0-9_.]{3,30}$' then
    raise exception 'USERNAME_INVALID';
  end if;

  if exists (
    select 1 from coinsort.users
    where lower(username) = v_name and id <> v_uid
  ) then
    raise exception 'USERNAME_TAKEN';
  end if;

  update coinsort.users set username = v_name where id = v_uid;
end;
$$;
grant execute on function coinsort.update_my_username(text) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Trạng thái các cách đăng nhập của chính mình
-- -----------------------------------------------------------------------------
-- Client không đọc được encrypted_password nên hỏi máy chủ. Trả cả email và
-- email đang chờ xác minh để màn Tài khoản có một nguồn sự thật duy nhất.
create or replace function coinsort.get_my_login_methods()
returns jsonb
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
declare
  v_uid uuid := auth.uid();
  r record;
begin
  if v_uid is null then
    raise exception 'NOT_LOGGED_IN';
  end if;

  select
    (u.encrypted_password is not null and u.encrypted_password <> '') as has_password,
    u.email,
    (u.email_confirmed_at is not null) as email_confirmed,
    nullif(u.email_change, '') as pending_email,
    (u.email like '%@noemail.coinsort.app') as is_synthetic_email
  into r
  from auth.users u
  where u.id = v_uid;

  return jsonb_build_object(
    'has_password', coalesce(r.has_password, false),
    'email', case when coalesce(r.is_synthetic_email, false) then null else r.email end,
    'email_confirmed', coalesce(r.email_confirmed, false) and not coalesce(r.is_synthetic_email, false),
    'pending_email', r.pending_email,
    'is_synthetic_email', coalesce(r.is_synthetic_email, false)
  );
end;
$$;
grant execute on function coinsort.get_my_login_methods() to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Bạn bè mạng xã hội đã đồng bộ
-- -----------------------------------------------------------------------------
create table if not exists coinsort.social_friends (
  user_id            uuid not null references coinsort.users(id) on delete cascade,
  provider           text not null check (provider in ('facebook', 'twitter', 'google')),
  friend_provider_id text not null,
  friend_name        text,
  updated_at         timestamptz not null default timezone('utc', now()),
  primary key (user_id, provider, friend_provider_id)
);
create index if not exists social_friends_provider_friend_idx
  on coinsort.social_friends (provider, friend_provider_id);

alter table coinsort.social_friends enable row level security;
drop policy if exists "Owner manages own social friends" on coinsort.social_friends;
create policy "Owner manages own social friends"
  on coinsort.social_friends for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Thay toàn bộ danh sách bạn của một provider bằng danh sách mới.
-- p_friends: jsonb array [{"id": "...", "name": "..."}, ...]
create or replace function coinsort.sync_social_friends(p_provider text, p_friends jsonb)
returns integer
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_count integer;
begin
  if v_uid is null then
    raise exception 'NOT_LOGGED_IN';
  end if;
  if p_provider not in ('facebook', 'twitter', 'google') then
    raise exception 'PROVIDER_INVALID';
  end if;

  delete from coinsort.social_friends
  where user_id = v_uid and provider = p_provider;

  insert into coinsort.social_friends (user_id, provider, friend_provider_id, friend_name)
  select v_uid, p_provider, f->>'id', left(f->>'name', 120)
  from jsonb_array_elements(coalesce(p_friends, '[]'::jsonb)) as f
  where coalesce(f->>'id', '') <> ''
  on conflict (user_id, provider, friend_provider_id) do update
    set friend_name = excluded.friend_name,
        updated_at  = timezone('utc', now());

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
grant execute on function coinsort.sync_social_friends(text, jsonb) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Gợi ý người để mời vào nhóm
-- -----------------------------------------------------------------------------
-- (a) Bạn Facebook/X đã đồng bộ và cũng có tài khoản Coinsort (khớp
--     auth.identities.provider_id — chỉ đọc được nhờ security definer).
-- (b) Người đang cùng ít nhất một nhóm chung (không tính nhóm cá nhân).
-- Không lộ email hay provider_id; chỉ trả hồ sơ công khai + nguồn gợi ý.
create or replace function coinsort.get_friend_suggestions()
returns table (
  id         uuid,
  username   text,
  full_name  text,
  avatar_url text,
  source     text
)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then return; end if;

  return query
  with social as (
    select distinct i.user_id as friend_id, sf.provider as src
    from coinsort.social_friends sf
    join auth.identities i
      on i.provider = sf.provider
     and i.provider_id = sf.friend_provider_id
    where sf.user_id = v_uid
  ),
  shared as (
    select distinct gm2.user_id as friend_id, 'group'::text as src
    from coinsort.group_members gm1
    join coinsort.groups g on g.id = gm1.group_id
    join coinsort.group_members gm2
      on gm2.group_id = gm1.group_id
     and gm2.user_id <> gm1.user_id
     and gm2.status = 'active'
    where gm1.user_id = v_uid
      and gm1.status = 'active'
      and g.is_personal = false
      and coalesce(g.status, 'active') = 'active'
  ),
  merged as (
    select friend_id, src from social
    union all
    select friend_id, src from shared
  ),
  ranked as (
    -- Ưu tiên nguồn mạng xã hội hơn "cùng nhóm" khi một người xuất hiện ở cả hai.
    select distinct on (friend_id) friend_id, src
    from merged
    order by friend_id, case when src = 'group' then 1 else 0 end
  )
  select u.id, u.username, u.full_name, u.avatar_url, r.src
  from ranked r
  join coinsort.users u on u.id = r.friend_id
  where u.id <> v_uid
    and coalesce(u.status, 'active') = 'active'
  order by case when r.src = 'group' then 1 else 0 end,
           u.full_name nulls last, u.username nulls last
  limit 50;
end;
$$;
grant execute on function coinsort.get_friend_suggestions() to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Dọn social_friends khi tài khoản bị xoá
-- -----------------------------------------------------------------------------
-- 007 anonymise coinsort.users (status = 'deleted') chứ không xoá hàng nên FK
-- cascade không chạy — dùng trigger để dữ liệu bạn bè không sót lại.
create or replace function coinsort.cleanup_social_friends_on_delete()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  if new.status = 'deleted' and coalesce(old.status, 'active') <> 'deleted' then
    delete from coinsort.social_friends where user_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists on_user_deleted_cleanup_social on coinsort.users;
create trigger on_user_deleted_cleanup_social
  after update of status on coinsort.users
  for each row execute procedure coinsort.cleanup_social_friends_on_delete();

commit;
