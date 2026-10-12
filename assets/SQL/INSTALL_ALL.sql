-- =============================================================================
-- COINSORT — CÀI MỚI TOÀN BỘ BACKEND VÀO SCHEMA `coinsort` (một lần chạy)
--
-- File này GỘP theo đúng thứ tự: 000 header → schema → scripts → migrations
-- 001..008 → seed. Dán toàn bộ vào Supabase Dashboard → SQL Editor → Run.
-- Dùng cho project Supabase TRỐNG. Sinh tự động — sửa file gốc rồi chạy lại
-- tool (scratchpad sql_to_coinsort.py) thay vì sửa tay ở đây.
--
-- SAU KHI CHẠY: Dashboard → Project Settings → Data API → Exposed schemas →
-- thêm `coinsort`. Rồi Authentication → Sign In / Up → provider Email: Confirm
-- email OFF, Secure email change OFF; User Signups: Allow manual linking ON
-- (xem docs/SOCIAL_AUTH_SETUP.md).
-- =============================================================================


-- ############################################################################
-- ## 000_schema_setup.sql
-- ############################################################################

-- =============================================================================
-- 000 — TẠO SCHEMA `coinsort` VÀ PHÂN QUYỀN NỀN
--
-- Chạy ĐẦU TIÊN trong Supabase Dashboard → SQL Editor (hoặc dùng INSTALL_ALL.sql
-- đã gộp sẵn). Idempotent.
--
-- Vì sao cần file này: mọi bảng/RPC của app nằm trong schema riêng `coinsort`
-- thay cho `public`. Với `public`, Supabase đã cài sẵn (1) grant usage cho
-- anon/authenticated/service_role và (2) default privileges để bảng/hàm/sequence
-- tạo mới tự có quyền cho các role đó. Schema tự tạo KHÔNG có gì cả → PostgREST
-- sẽ trả 42501 permission denied cho mọi truy vấn. Header này tái tạo đúng mặc
-- định ấy cho `coinsort`; migration 005 vẫn revoke chọn lọc các hàm nội bộ như cũ.
--
-- ⚠️  BƯỚC TAY BẮT BUỘC (không làm được bằng SQL này):
--     Dashboard → Project Settings → Data API → "Exposed schemas" → thêm `coinsort`
--     (giữ nguyên public, graphql_public). Không có bước này client nhận
--     "The schema must be one of the following: public, graphql_public".
--     Client Flutter đã đặt PostgrestClientOptions(schema: 'coinsort').
-- =============================================================================

create schema if not exists coinsort;

grant usage on schema coinsort to postgres, anon, authenticated, service_role;

-- Đối tượng do role postgres (SQL Editor) tạo SAU đây tự có quyền — y như public.
alter default privileges for role postgres in schema coinsort
  grant all on tables to postgres, anon, authenticated, service_role;
alter default privileges for role postgres in schema coinsort
  grant all on functions to postgres, anon, authenticated, service_role;
alter default privileges for role postgres in schema coinsort
  grant all on sequences to postgres, anon, authenticated, service_role;

-- Đối tượng đã tồn tại (khi chạy lại header trên schema cũ).
grant all on all tables in schema coinsort to postgres, anon, authenticated, service_role;
grant all on all sequences in schema coinsort to postgres, anon, authenticated, service_role;
grant all on all functions in schema coinsort to postgres, anon, authenticated, service_role;

-- Extension dùng chung (Supabase đặt ở schema extensions; if not exists = no-op).
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- (Tuỳ chọn, thay cho bước tay ở trên — chỉ dùng khi biết chắc danh sách schema
--  đang expose. Bỏ comment 2 dòng dưới nếu muốn:)
-- alter role authenticator set pgrst.db_schemas = 'public, graphql_public, coinsort';
-- notify pgrst, 'reload config';


-- ############################################################################
-- ## schema.sql
-- ############################################################################

-- =============================================================================
-- SCHEMA: Bảng, trigger, RLS. Chạy trong Supabase Dashboard → SQL Editor.
--
-- ⚠️  FILE NÀY XOÁ TOÀN BỘ BẢNG. Chỉ dùng cho dự án MỚI.
--     Database đang có dữ liệu → chạy assets/SQL/migrations/001 → 002 → 003.
--
-- Thứ tự cài mới:
--   schema.sql → scripts.sql → migrations/001 → 002 → 003 → seed.sql
--   (các file migrations đều idempotent nên chạy trên DB mới cũng an toàn)
-- =============================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pg_trgm;

-- ---------- 1. DROP (theo thứ tự phụ thuộc FK) ----------
drop table if exists coinsort.transaction_audit cascade;
drop table if exists coinsort.group_settlements cascade;
drop table if exists coinsort.transaction_splits cascade;
drop table if exists coinsort.transaction_tags cascade;
drop table if exists coinsort.transactions cascade;
drop table if exists coinsort.group_invitations cascade;
drop table if exists coinsort.group_members cascade;
drop table if exists coinsort.groups cascade;
drop table if exists coinsort.tags cascade;
drop table if exists coinsort.debts_loans cascade;
drop table if exists coinsort.recurring_transactions cascade;
drop table if exists coinsort.budgets cascade;
drop table if exists coinsort.categories cascade;
drop table if exists coinsort.accounts cascade;
drop table if exists coinsort.users cascade;

-- ---------- 2. USERS ----------
create table coinsort.users (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  full_name text,
  avatar_url text,
  is_premium boolean default false,
  role text check (role in ('admin', 'user')) default 'user',
  status text check (status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 3. GROUPS ----------
create table coinsort.groups (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  is_personal boolean not null default false,
  invite_code text unique,
  status text check (status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 4. GROUP_MEMBERS ----------
create table coinsort.group_members (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references coinsort.groups(id) on delete cascade not null,
  user_id uuid references coinsort.users(id) on delete cascade not null,
  role text check (role in ('admin', 'member')) not null default 'member',
  status text check (status in ('active', 'left', 'deleted')) default 'active',
  joined_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(group_id, user_id)
);

-- ---------- 4b. GROUP_INVITATIONS ----------
create table coinsort.group_invitations (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references coinsort.groups(id) on delete cascade not null,
  user_id uuid references coinsort.users(id) on delete cascade not null,
  invited_by uuid references coinsort.users(id) on delete cascade not null,
  status text check (status in ('pending', 'accepted', 'declined')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(group_id, user_id)
);

-- ---------- 5. ACCOUNTS ----------
-- balance: asset = số tiền đang có; liability = số tiền đang nợ (luôn dương).
-- opening_balance: số dư khởi tạo, tách khỏi tác động của sổ giao dịch, để
-- recalc_account_balance() dựng lại được số dư từ sổ cái.
-- group_id: null = ví cá nhân; có giá trị = ví dùng chung của nhóm.
create table coinsort.accounts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references coinsort.users(id) on delete cascade not null,
  group_id uuid references coinsort.groups(id) on delete cascade,
  name text not null,
  account_type text check (account_type in ('asset', 'liability')) not null default 'asset',
  balance numeric default 0 not null,
  opening_balance numeric default 0 not null,
  credit_limit numeric default 0,
  statement_date integer check (statement_date between 1 and 31),
  payment_date integer check (payment_date between 1 and 31),
  include_in_total boolean default true,
  currency text default 'VND' not null,
  status text check (status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 6. CATEGORIES ----------
create table coinsort.categories (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references coinsort.users(id) on delete cascade,
  parent_id uuid references coinsort.categories(id) on delete cascade,
  name text not null,
  type text check (type in ('income', 'expense')) not null,
  icon_name text not null,
  color_hex text not null,
  is_default boolean default false,
  order_index integer default 0,
  is_active boolean default true,
  status text check (status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 7. TRANSACTIONS ----------
create table coinsort.transactions (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references coinsort.groups(id) on delete cascade not null,
  account_id uuid references coinsort.accounts(id) on delete cascade not null,
  to_account_id uuid references coinsort.accounts(id) on delete cascade,
  category_id uuid references coinsort.categories(id) on delete set null,
  type text check (type in ('income', 'expense', 'transfer')) not null,
  amount numeric not null check (amount > 0),
  fee_amount numeric default 0 check (fee_amount >= 0),
  transaction_date timestamp with time zone not null,
  note text,
  image_url text,
  payee text,
  status text check (status in ('cleared', 'pending')) default 'cleared',
  row_status text check (row_status in ('active', 'deleted')) default 'active',
  split_mode text check (split_mode in ('none', 'equal', 'exact', 'percent', 'shares')) default 'none',
  created_by uuid references coinsort.users(id) on delete set null not null,
  paid_by uuid references coinsort.users(id) on delete set null not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 7b. TRANSACTION_SPLITS: ai gánh bao nhiêu trong một khoản chi ----------
create table coinsort.transaction_splits (
  transaction_id uuid references coinsort.transactions(id) on delete cascade,
  user_id uuid references coinsort.users(id) on delete cascade,
  share_amount numeric not null check (share_amount >= 0),
  primary key (transaction_id, user_id)
);

-- ---------- 7c. GROUP_SETTLEMENTS: ghi nhận trả nợ giữa các thành viên ----------
create table coinsort.group_settlements (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references coinsort.groups(id) on delete cascade not null,
  from_user uuid references coinsort.users(id) on delete cascade not null,
  to_user uuid references coinsort.users(id) on delete cascade not null,
  amount numeric not null check (amount > 0),
  note text,
  settled_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_by uuid references coinsort.users(id) on delete set null,
  row_status text check (row_status in ('active', 'deleted')) default 'active',
  check (from_user <> to_user)
);

-- ---------- 7d. TRANSACTION_AUDIT: nhật ký ai sửa gì ----------
create table coinsort.transaction_audit (
  id bigserial primary key,
  transaction_id uuid not null,
  group_id uuid,
  action text not null check (action in ('insert', 'update', 'delete')),
  changed_by uuid,
  old_row jsonb,
  new_row jsonb,
  changed_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 8. TAGS ----------
create table coinsort.tags (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references coinsort.users(id) on delete cascade not null,
  name text not null,
  color_hex text not null,
  status text check (status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 9. TRANSACTION_TAGS ----------
create table coinsort.transaction_tags (
  transaction_id uuid references coinsort.transactions(id) on delete cascade,
  tag_id uuid references coinsort.tags(id) on delete cascade,
  primary key (transaction_id, tag_id)
);

-- ---------- 10. BUDGETS ----------
create table coinsort.budgets (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references coinsort.users(id) on delete cascade not null,
  category_id uuid references coinsort.categories(id) on delete cascade not null,
  amount numeric not null check (amount > 0),
  period text check (period in ('weekly', 'monthly', 'yearly', 'custom')) not null,
  start_date date not null,
  end_date date not null,
  status text check (status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 11. RECURRING_TRANSACTIONS ----------
create table coinsort.recurring_transactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references coinsort.users(id) on delete cascade not null,
  account_id uuid references coinsort.accounts(id) on delete cascade not null,
  category_id uuid references coinsort.categories(id) on delete set null,
  type text check (type in ('income', 'expense')) not null,
  amount numeric not null check (amount > 0),
  note text,
  frequency text check (frequency in ('daily', 'weekly', 'monthly', 'yearly')) not null,
  next_date date not null,
  is_active boolean default true,
  status text check (status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 12. DEBTS_LOANS ----------
create table coinsort.debts_loans (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references coinsort.users(id) on delete cascade not null,
  person_name text not null,
  type text check (type in ('debt', 'loan')) not null,
  amount numeric not null check (amount > 0),
  remaining_amount numeric not null check (remaining_amount >= 0),
  due_date date,
  status text check (status in ('active', 'paid')) default 'active',
  row_status text check (row_status in ('active', 'deleted')) default 'active',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ---------- 13. TRIGGER: Cập nhật số dư ví ----------
-- apply_balance_delta là nơi DUY NHẤT được phép sửa accounts.balance.
-- p_delta là dòng tiền VÀO ví (dương = tiền vào, âm = tiền ra).
-- Ví 'liability' đảo dấu: tiền ra (quẹt thẻ) làm số nợ TĂNG.
create or replace function coinsort.apply_balance_delta(p_account_id uuid, p_delta numeric)
returns void
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  if p_account_id is null or p_delta is null or p_delta = 0 then return; end if;
  update coinsort.accounts a
     set balance = a.balance
                 + (case when a.account_type = 'liability' then -1 else 1 end) * p_delta,
         updated_at = timezone('utc'::text, now())
   where a.id = p_account_id;
end;
$$;

-- Một trigger cho cả INSERT / UPDATE / DELETE, hiểu cả xoá mềm:
-- đảo ngược tác động của bản ghi cũ (nếu đang active), rồi áp dụng bản ghi mới
-- (nếu active). Công thức này phủ hết: thêm, sửa, xoá mềm, khôi phục, xoá cứng.
create or replace function coinsort.update_account_balance()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_old_active boolean := false;
  v_new_active boolean := false;
begin
  if tg_op in ('UPDATE', 'DELETE') then
    v_old_active := coalesce(old.row_status, 'active') = 'active';
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    v_new_active := coalesce(new.row_status, 'active') = 'active';
  end if;

  if v_old_active then
    if old.type = 'expense' then
      perform coinsort.apply_balance_delta(old.account_id, old.amount);
    elsif old.type = 'income' then
      perform coinsort.apply_balance_delta(old.account_id, -old.amount);
    elsif old.type = 'transfer' then
      perform coinsort.apply_balance_delta(old.account_id, old.amount + coalesce(old.fee_amount, 0));
      perform coinsort.apply_balance_delta(old.to_account_id, -old.amount);
    end if;
  end if;

  if v_new_active then
    if new.type = 'expense' then
      perform coinsort.apply_balance_delta(new.account_id, -new.amount);
    elsif new.type = 'income' then
      perform coinsort.apply_balance_delta(new.account_id, new.amount);
    elsif new.type = 'transfer' then
      perform coinsort.apply_balance_delta(new.account_id, -(new.amount + coalesce(new.fee_amount, 0)));
      perform coinsort.apply_balance_delta(new.to_account_id, new.amount);
    end if;
  end if;

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists on_transaction_inserted on coinsort.transactions;
drop trigger if exists on_transaction_deleted  on coinsort.transactions;
drop trigger if exists on_transaction_changed  on coinsort.transactions;
create trigger on_transaction_changed
  after insert or update or delete on coinsort.transactions
  for each row execute function coinsort.update_account_balance();

-- ---------- 13b. TRIGGER: updated_at ----------
create or replace function coinsort.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists on_transaction_touch on coinsort.transactions;
create trigger on_transaction_touch
  before update on coinsort.transactions
  for each row execute function coinsort.touch_updated_at();

-- ---------- 13c. TRIGGER: nhật ký thay đổi ----------
create or replace function coinsort.log_transaction_change()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_action text;
begin
  if tg_op = 'INSERT' then
    v_action := 'insert';
  elsif tg_op = 'DELETE' then
    v_action := 'delete';
  elsif coalesce(new.row_status, 'active') = 'deleted'
    and coalesce(old.row_status, 'active') = 'active' then
    v_action := 'delete';
  else
    v_action := 'update';
  end if;

  insert into coinsort.transaction_audit (transaction_id, group_id, action, changed_by, old_row, new_row)
  values (
    coalesce(new.id, old.id),
    coalesce(new.group_id, old.group_id),
    v_action,
    auth.uid(),
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end
  );

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists on_transaction_audit on coinsort.transactions;
create trigger on_transaction_audit
  after insert or update or delete on coinsort.transactions
  for each row execute function coinsort.log_transaction_change();

-- ---------- 14. TRIGGER: Đăng ký -> users + nhóm cá nhân + ví mặc định ----------
create or replace function coinsort.handle_new_user()
returns trigger as $$
declare
  personal_group_id uuid;
begin
  insert into coinsort.users (id, full_name, avatar_url, username, role, status)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    coalesce(new.raw_user_meta_data->>'username', 'user_' || left(new.id::text, 8)),
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
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure coinsort.handle_new_user();

-- ---------- 15. RLS: users ----------
alter table coinsort.users enable row level security;
drop policy if exists "Users can view own profile" on coinsort.users;
create policy "Users can view own profile" on coinsort.users for select using (auth.uid() = id);
drop policy if exists "Users can update own profile" on coinsort.users;
create policy "Users can update own profile" on coinsort.users for update using (auth.uid() = id);

-- ---------- 16. RLS: groups ----------
alter table coinsort.groups enable row level security;
drop policy if exists "Users can view groups they belong to" on coinsort.groups;
create policy "Users can view groups they belong to"
  on coinsort.groups for select
  using (exists (select 1 from coinsort.group_members gm where gm.group_id = id and gm.user_id = auth.uid() and gm.status = 'active'));
-- KHÔNG có policy INSERT: tạo nhóm bắt buộc đi qua RPC create_group()
-- (security definer) để không ai chèn được bản ghi nhóm tuỳ ý.
drop policy if exists "Users can insert groups" on coinsort.groups;
drop policy if exists "Admins can update own group" on coinsort.groups;
create policy "Admins can update own group"
  on coinsort.groups for update
  using (exists (select 1 from coinsort.group_members gm where gm.group_id = id and gm.user_id = auth.uid() and gm.role = 'admin' and gm.status = 'active'));

-- ---------- 17. RLS: group_members ----------
alter table coinsort.group_members enable row level security;
drop policy if exists "Users can view own memberships" on coinsort.group_members;
create policy "Users can view own memberships"
  on coinsort.group_members for select using (user_id = auth.uid());
drop policy if exists "Users can view members of their groups" on coinsort.group_members;
drop policy if exists "Users can join group (self)" on coinsort.group_members;
create policy "Users can join group (self)"
  on coinsort.group_members for insert with check (user_id = auth.uid());
drop policy if exists "Admins can insert members" on coinsort.group_members;
create policy "Admins can insert members"
  on coinsort.group_members for insert
  with check (exists (select 1 from coinsort.group_members gm where gm.group_id = group_members.group_id and gm.user_id = auth.uid() and gm.role = 'admin' and gm.status = 'active'));
drop policy if exists "Admins can update members" on coinsort.group_members;
create policy "Admins can update members"
  on coinsort.group_members for update
  using (exists (select 1 from coinsort.group_members gm where gm.group_id = group_members.group_id and gm.user_id = auth.uid() and gm.role = 'admin'));

alter table coinsort.group_invitations enable row level security;
drop policy if exists "Users can view own invitations" on coinsort.group_invitations;
create policy "Users can view own invitations"
  on coinsort.group_invitations for select using (user_id = auth.uid());
drop policy if exists "Admins can insert invitations" on coinsort.group_invitations;
create policy "Admins can insert invitations"
  on coinsort.group_invitations for insert with check (invited_by = auth.uid());
drop policy if exists "Users can update own invitations" on coinsort.group_invitations;
create policy "Users can update own invitations"
  on coinsort.group_invitations for update using (user_id = auth.uid());

-- ---------- 18. RLS: accounts ----------
alter table coinsort.accounts enable row level security;
drop policy if exists "Users can manage own accounts" on coinsort.accounts;
create policy "Users can manage own accounts"
  on coinsort.accounts for all
  using (
    auth.uid() = user_id
    or (group_id is not null and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = accounts.group_id and gm.user_id = auth.uid() and gm.status = 'active'))
  )
  with check (
    auth.uid() = user_id
    or (group_id is not null and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = accounts.group_id and gm.user_id = auth.uid() and gm.status = 'active'))
  );

-- ---------- 19. RLS: categories ----------
alter table coinsort.categories enable row level security;
drop policy if exists "Users can view categories" on coinsort.categories;
create policy "Users can view categories"
  on coinsort.categories for select
  using ((user_id is null or auth.uid() = user_id) and (status is null or status = 'active') and is_active = true);
drop policy if exists "Users can manage own categories" on coinsort.categories;
create policy "Users can manage own categories" on coinsort.categories for all using (auth.uid() = user_id);

-- ---------- 20. RLS: transactions ----------
alter table coinsort.transactions enable row level security;
drop policy if exists "Users can view group transactions" on coinsort.transactions;
drop policy if exists "Users can insert group transactions" on coinsort.transactions;
drop policy if exists "Users can update group transactions" on coinsort.transactions;
drop policy if exists "Users can delete group transactions" on coinsort.transactions;
create policy "Users can view group transactions"
  on coinsort.transactions for select
  using (exists (select 1 from coinsort.group_members gm where gm.group_id = transactions.group_id and gm.user_id = auth.uid() and gm.status = 'active') and (row_status is null or row_status = 'active'));
create policy "Users can insert group transactions"
  on coinsort.transactions for insert
  with check (exists (select 1 from coinsort.group_members gm where gm.group_id = transactions.group_id and gm.user_id = auth.uid() and gm.status = 'active'));
create policy "Users can update group transactions"
  on coinsort.transactions for update
  using (exists (select 1 from coinsort.group_members gm where gm.group_id = transactions.group_id and gm.user_id = auth.uid() and gm.status = 'active'));
create policy "Users can delete group transactions"
  on coinsort.transactions for delete
  using (exists (select 1 from coinsort.group_members gm where gm.group_id = transactions.group_id and gm.user_id = auth.uid() and gm.status = 'active'));

-- ---------- 21. RLS: tags, budgets, recurring, debts_loans, transaction_tags ----------
alter table coinsort.tags enable row level security;
drop policy if exists "Users can manage own tags" on coinsort.tags;
create policy "Users can manage own tags" on coinsort.tags for all using (auth.uid() = user_id);

alter table coinsort.budgets enable row level security;
drop policy if exists "Users can manage own budgets" on coinsort.budgets;
create policy "Users can manage own budgets" on coinsort.budgets for all using (auth.uid() = user_id);

alter table coinsort.recurring_transactions enable row level security;
drop policy if exists "Users can manage own recurring" on coinsort.recurring_transactions;
create policy "Users can manage own recurring" on coinsort.recurring_transactions for all using (auth.uid() = user_id);

alter table coinsort.debts_loans enable row level security;
drop policy if exists "Users can manage own debts" on coinsort.debts_loans;
create policy "Users can manage own debts" on coinsort.debts_loans for all using (auth.uid() = user_id);

alter table coinsort.transaction_tags enable row level security;
drop policy if exists "Users can manage transaction_tags" on coinsort.transaction_tags;
create policy "Users can manage transaction_tags" on coinsort.transaction_tags for all
  using (exists (select 1 from coinsort.transactions t join coinsort.group_members gm on gm.group_id = t.group_id and gm.user_id = auth.uid() and gm.status = 'active' where t.id = transaction_id));

-- ---------- 22. RLS: splits, settlements, audit ----------
alter table coinsort.transaction_splits enable row level security;
drop policy if exists "Members manage splits of their group" on coinsort.transaction_splits;
create policy "Members manage splits of their group"
  on coinsort.transaction_splits for all
  using (exists (
    select 1 from coinsort.transactions t
    join coinsort.group_members gm on gm.group_id = t.group_id and gm.user_id = auth.uid() and gm.status = 'active'
    where t.id = transaction_splits.transaction_id))
  with check (exists (
    select 1 from coinsort.transactions t
    join coinsort.group_members gm on gm.group_id = t.group_id and gm.user_id = auth.uid() and gm.status = 'active'
    where t.id = transaction_splits.transaction_id));

alter table coinsort.group_settlements enable row level security;
drop policy if exists "Members manage settlements" on coinsort.group_settlements;
create policy "Members manage settlements"
  on coinsort.group_settlements for all
  using (exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = group_settlements.group_id and gm.user_id = auth.uid() and gm.status = 'active'))
  with check (exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = group_settlements.group_id and gm.user_id = auth.uid() and gm.status = 'active'));

alter table coinsort.transaction_audit enable row level security;
drop policy if exists "Members can read group audit" on coinsort.transaction_audit;
create policy "Members can read group audit"
  on coinsort.transaction_audit for select
  using (exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = transaction_audit.group_id and gm.user_id = auth.uid() and gm.status = 'active'));


-- ############################################################################
-- ## scripts.sql
-- ############################################################################

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


-- ############################################################################
-- ## migrations/001_balance_integrity.sql
-- ############################################################################

-- =============================================================================
-- MIGRATION 001 — Toàn vẹn số dư (Giai đoạn 0)
--
-- Chạy trên database ĐANG CÓ DỮ LIỆU. An toàn, không xoá bảng, chạy lại được
-- nhiều lần (idempotent).
--
-- Sửa các lỗi:
--   #1  Sửa giao dịch (UPDATE) không cập nhật số dư ví.
--   #2  Xoá mềm (row_status='deleted') không hoàn tiền về ví.
--   #7a Ví loại 'liability' bị cộng/trừ sai dấu → tài sản ròng sai.
--
-- Bổ sung:
--   - accounts.opening_balance  : số dư khởi tạo, tách khỏi sổ giao dịch.
--   - apply_balance_delta()     : điểm duy nhất được phép sửa accounts.balance.
--   - recalc_account_balance()  : dựng lại số dư từ sổ cái.
--   - transaction_audit         : nhật ký ai sửa gì, lúc nào.
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. opening_balance: tách số dư khởi tạo khỏi tác động của sổ giao dịch
-- ---------------------------------------------------------------------------
alter table coinsort.accounts
  add column if not exists opening_balance numeric not null default 0;

-- Khôi phục số dư khởi tạo thật:
--   opening_balance = balance hiện tại − tổng tác động mà trigger CŨ đã ghi.
--
-- Trigger cũ chạy khi INSERT cho MỌI dòng (kể cả dòng sau này bị xoá mềm, vì
-- xoá mềm không kích hoạt trigger DELETE). Dòng bị xoá cứng đã được hoàn lại
-- và không còn trong bảng. Nên tổng tác động cũ = tổng trên TẤT CẢ dòng còn lại,
-- không phân biệt row_status, không phân biệt loại ví.
--
-- Chỉ chạy một lần duy nhất (đánh dấu bằng cột opening_balance_migrated).
alter table coinsort.accounts
  add column if not exists opening_balance_migrated boolean not null default false;

update coinsort.accounts a
set opening_balance = a.balance - coalesce((
      select sum(
        case
          when t.type = 'expense'  and t.account_id    = a.id then -t.amount
          when t.type = 'income'   and t.account_id    = a.id then  t.amount
          when t.type = 'transfer' and t.account_id    = a.id then -(t.amount + coalesce(t.fee_amount, 0))
          when t.type = 'transfer' and t.to_account_id = a.id then  t.amount
          else 0
        end)
      from coinsort.transactions t
      where t.account_id = a.id or t.to_account_id = a.id
    ), 0),
    opening_balance_migrated = true
where a.opening_balance_migrated = false;

-- ---------------------------------------------------------------------------
-- 2. apply_balance_delta — nơi DUY NHẤT được sửa accounts.balance
-- ---------------------------------------------------------------------------
-- p_delta là dòng tiền VÀO tài khoản (dương = tiền vào, âm = tiền ra).
--
-- Quy ước dấu:
--   asset     — balance = số tiền đang có.    Tiền vào → tăng.
--   liability — balance = số tiền đang nợ.    Tiền ra (quẹt thẻ) → nợ tăng.
-- Nhờ vậy Tài sản ròng = tổng asset − tổng liability luôn đúng.
create or replace function coinsort.apply_balance_delta(
  p_account_id uuid,
  p_delta      numeric
)
returns void
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  if p_account_id is null or p_delta is null or p_delta = 0 then
    return;
  end if;
  update coinsort.accounts a
     set balance = a.balance
                 + (case when a.account_type = 'liability' then -1 else 1 end) * p_delta,
         updated_at = timezone('utc'::text, now())
   where a.id = p_account_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Trigger số dư hợp nhất: INSERT + UPDATE + DELETE, hiểu cả xoá mềm
-- ---------------------------------------------------------------------------
-- Nguyên tắc: ĐẢO NGƯỢC tác động của bản ghi cũ (nếu nó đang active), rồi
-- ÁP DỤNG tác động của bản ghi mới (nếu nó active). Một công thức phủ hết:
--   thêm mới       (old = null,   new active)   → chỉ áp dụng
--   sửa            (old active,   new active)   → đảo cũ + áp mới
--   xoá mềm        (old active,   new deleted)  → chỉ đảo cũ
--   khôi phục      (old deleted,  new active)   → chỉ áp mới
--   xoá cứng       (old active,   new = null)   → chỉ đảo cũ
create or replace function coinsort.update_account_balance()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_old_active boolean := false;
  v_new_active boolean := false;
begin
  if tg_op in ('UPDATE', 'DELETE') then
    v_old_active := coalesce(old.row_status, 'active') = 'active';
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    v_new_active := coalesce(new.row_status, 'active') = 'active';
  end if;

  -- (a) Đảo ngược bản ghi cũ
  if v_old_active then
    if old.type = 'expense' then
      perform coinsort.apply_balance_delta(old.account_id, old.amount);
    elsif old.type = 'income' then
      perform coinsort.apply_balance_delta(old.account_id, -old.amount);
    elsif old.type = 'transfer' then
      perform coinsort.apply_balance_delta(old.account_id, old.amount + coalesce(old.fee_amount, 0));
      perform coinsort.apply_balance_delta(old.to_account_id, -old.amount);
    end if;
  end if;

  -- (b) Áp dụng bản ghi mới
  if v_new_active then
    if new.type = 'expense' then
      perform coinsort.apply_balance_delta(new.account_id, -new.amount);
    elsif new.type = 'income' then
      perform coinsort.apply_balance_delta(new.account_id, new.amount);
    elsif new.type = 'transfer' then
      perform coinsort.apply_balance_delta(new.account_id, -(new.amount + coalesce(new.fee_amount, 0)));
      perform coinsort.apply_balance_delta(new.to_account_id, new.amount);
    end if;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists on_transaction_inserted on coinsort.transactions;
drop trigger if exists on_transaction_deleted  on coinsort.transactions;
drop trigger if exists on_transaction_changed  on coinsort.transactions;

create trigger on_transaction_changed
  after insert or update or delete on coinsort.transactions
  for each row execute function coinsort.update_account_balance();

-- ---------------------------------------------------------------------------
-- 4. updated_at tự động
-- ---------------------------------------------------------------------------
create or replace function coinsort.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists on_transaction_touch on coinsort.transactions;
create trigger on_transaction_touch
  before update on coinsort.transactions
  for each row execute function coinsort.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 5. Nhật ký thay đổi giao dịch
-- ---------------------------------------------------------------------------
create table if not exists coinsort.transaction_audit (
  id             bigserial primary key,
  transaction_id uuid not null,
  group_id       uuid,
  action         text not null check (action in ('insert', 'update', 'delete')),
  changed_by     uuid,
  old_row        jsonb,
  new_row        jsonb,
  changed_at     timestamp with time zone default timezone('utc'::text, now()) not null
);

create or replace function coinsort.log_transaction_change()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_action text;
begin
  if tg_op = 'INSERT' then
    v_action := 'insert';
  elsif tg_op = 'DELETE' then
    v_action := 'delete';
  elsif coalesce(new.row_status, 'active') = 'deleted'
    and coalesce(old.row_status, 'active') = 'active' then
    v_action := 'delete';
  else
    v_action := 'update';
  end if;

  insert into coinsort.transaction_audit (transaction_id, group_id, action, changed_by, old_row, new_row)
  values (
    coalesce(new.id, old.id),
    coalesce(new.group_id, old.group_id),
    v_action,
    auth.uid(),
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end
  );

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists on_transaction_audit on coinsort.transactions;
create trigger on_transaction_audit
  after insert or update or delete on coinsort.transactions
  for each row execute function coinsort.log_transaction_change();

alter table coinsort.transaction_audit enable row level security;
drop policy if exists "Members can read group audit" on coinsort.transaction_audit;
create policy "Members can read group audit"
  on coinsort.transaction_audit for select
  using (exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = transaction_audit.group_id
      and gm.user_id = auth.uid()
      and gm.status = 'active'
  ));

-- ---------------------------------------------------------------------------
-- 6. Dựng lại số dư từ sổ cái (đối soát)
-- ---------------------------------------------------------------------------
create or replace function coinsort.recalc_account_balance(p_account_id uuid)
returns numeric
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_account   coinsort.accounts%rowtype;
  v_delta     numeric;
  v_sign      integer;
  v_balance   numeric;
begin
  select * into v_account from coinsort.accounts where id = p_account_id;
  if not found then
    return null;
  end if;

  -- Chỉ chủ ví mới được đối soát. (Migration 002 mở rộng cho ví dùng chung của nhóm.)
  if v_account.user_id is distinct from auth.uid() then
    raise exception 'Không có quyền đối soát ví này';
  end if;

  select coalesce(sum(
    case
      when t.type = 'expense'  and t.account_id    = p_account_id then -t.amount
      when t.type = 'income'   and t.account_id    = p_account_id then  t.amount
      when t.type = 'transfer' and t.account_id    = p_account_id then -(t.amount + coalesce(t.fee_amount, 0))
      when t.type = 'transfer' and t.to_account_id = p_account_id then  t.amount
      else 0
    end), 0)
  into v_delta
  from coinsort.transactions t
  where (t.account_id = p_account_id or t.to_account_id = p_account_id)
    and coalesce(t.row_status, 'active') = 'active';

  v_sign := case when v_account.account_type = 'liability' then -1 else 1 end;
  v_balance := v_account.opening_balance + v_sign * v_delta;

  update coinsort.accounts
     set balance = v_balance,
         updated_at = timezone('utc'::text, now())
   where id = p_account_id;

  return v_balance;
end;
$$;
grant execute on function coinsort.recalc_account_balance(uuid) to authenticated;

-- Đối soát toàn bộ ví mà user hiện tại có quyền. Trả về danh sách ví bị lệch.
create or replace function coinsort.recalc_my_balances()
returns table (account_id uuid, account_name text, old_balance numeric, new_balance numeric)
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  r record;
  v_new numeric;
begin
  for r in
    select a.id, a.name, a.balance
    from coinsort.accounts a
    where coalesce(a.status, 'active') = 'active'
      and a.user_id = auth.uid()
  loop
    v_new := coinsort.recalc_account_balance(r.id);
    if v_new is distinct from r.balance then
      account_id   := r.id;
      account_name := r.name;
      old_balance  := r.balance;
      new_balance  := v_new;
      return next;
    end if;
  end loop;
end;
$$;
grant execute on function coinsort.recalc_my_balances() to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- 7. ĐỐI SOÁT TOÀN HỆ THỐNG — chạy MỘT LẦN ngay sau migration
-- ---------------------------------------------------------------------------
-- Sửa mọi chênh lệch do lỗi #1, #2 và dấu ví nợ gây ra từ trước tới nay.
-- Chạy riêng khối này trong SQL Editor (quyền owner, bỏ qua kiểm tra RLS).
do $$
declare
  r record;
  v_delta numeric;
  v_sign  integer;
begin
  for r in select id, account_type, opening_balance from coinsort.accounts loop
    select coalesce(sum(
      case
        when t.type = 'expense'  and t.account_id    = r.id then -t.amount
        when t.type = 'income'   and t.account_id    = r.id then  t.amount
        when t.type = 'transfer' and t.account_id    = r.id then -(t.amount + coalesce(t.fee_amount, 0))
        when t.type = 'transfer' and t.to_account_id = r.id then  t.amount
        else 0
      end), 0)
    into v_delta
    from coinsort.transactions t
    where (t.account_id = r.id or t.to_account_id = r.id)
      and coalesce(t.row_status, 'active') = 'active';

    v_sign := case when r.account_type = 'liability' then -1 else 1 end;

    update coinsort.accounts
       set balance = r.opening_balance + v_sign * v_delta,
           updated_at = timezone('utc'::text, now())
     where id = r.id;
  end loop;
end $$;


-- ############################################################################
-- ## migrations/002_group_splits.sql
-- ############################################################################

-- =============================================================================
-- MIGRATION 002 — Mô hình nhóm hoàn chỉnh (Giai đoạn 1)
--
-- Chạy SAU 001_balance_integrity.sql. Idempotent.
--
-- Sửa các lỗi:
--   #3  Ví thuộc cá nhân nhưng giao dịch thuộc nhóm → thành viên khác không
--       đọc được tên ví. Giải pháp: accounts.group_id (ví dùng chung).
--   #4  Không có chia tiền / quyết toán. Giải pháp: transaction_splits,
--       group_settlements, get_group_balances().
--
-- Bổ sung:
--   - create_transaction() / update_transaction() : ghi giao dịch + phần chia
--     trong MỘT transaction DB, có kiểm tra quyền.
--   - Mã mời nhóm thay cho việc vào nhóm chỉ bằng UUID.
--   - Siết RLS: bỏ "insert groups with check (true)".
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Ví dùng chung của nhóm
-- ---------------------------------------------------------------------------
alter table coinsort.accounts
  add column if not exists group_id uuid references coinsort.groups(id) on delete cascade;

comment on column coinsort.accounts.group_id is
  'Null = ví cá nhân. Có giá trị = ví dùng chung, mọi thành viên nhóm đọc/ghi được.';

drop policy if exists "Users can manage own accounts" on coinsort.accounts;
create policy "Users can manage own accounts"
  on coinsort.accounts for all
  using (
    auth.uid() = user_id
    or (group_id is not null and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = accounts.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    ))
  )
  with check (
    auth.uid() = user_id
    or (group_id is not null and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = accounts.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    ))
  );

-- Cho phép đối soát ví dùng chung (mở rộng hàm ở migration 001).
create or replace function coinsort.recalc_account_balance(p_account_id uuid)
returns numeric
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_account coinsort.accounts%rowtype;
  v_delta   numeric;
  v_sign    integer;
  v_balance numeric;
begin
  select * into v_account from coinsort.accounts where id = p_account_id;
  if not found then return null; end if;

  if v_account.user_id is distinct from auth.uid()
     and not (v_account.group_id is not null and exists (
       select 1 from coinsort.group_members gm
       where gm.group_id = v_account.group_id
         and gm.user_id = auth.uid()
         and gm.status = 'active'))
  then
    raise exception 'Không có quyền đối soát ví này';
  end if;

  select coalesce(sum(
    case
      when t.type = 'expense'  and t.account_id    = p_account_id then -t.amount
      when t.type = 'income'   and t.account_id    = p_account_id then  t.amount
      when t.type = 'transfer' and t.account_id    = p_account_id then -(t.amount + coalesce(t.fee_amount, 0))
      when t.type = 'transfer' and t.to_account_id = p_account_id then  t.amount
      else 0
    end), 0)
  into v_delta
  from coinsort.transactions t
  where (t.account_id = p_account_id or t.to_account_id = p_account_id)
    and coalesce(t.row_status, 'active') = 'active';

  v_sign := case when v_account.account_type = 'liability' then -1 else 1 end;
  v_balance := v_account.opening_balance + v_sign * v_delta;

  update coinsort.accounts
     set balance = v_balance, updated_at = timezone('utc'::text, now())
   where id = p_account_id;

  return v_balance;
end;
$$;
grant execute on function coinsort.recalc_account_balance(uuid) to authenticated;

create or replace function coinsort.recalc_my_balances()
returns table (account_id uuid, account_name text, old_balance numeric, new_balance numeric)
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  r record;
  v_new numeric;
begin
  for r in
    select a.id, a.name, a.balance
    from coinsort.accounts a
    where coalesce(a.status, 'active') = 'active'
      and (a.user_id = auth.uid()
           or (a.group_id is not null and exists (
             select 1 from coinsort.group_members gm
             where gm.group_id = a.group_id and gm.user_id = auth.uid() and gm.status = 'active')))
  loop
    v_new := coinsort.recalc_account_balance(r.id);
    if v_new is distinct from r.balance then
      account_id := r.id; account_name := r.name;
      old_balance := r.balance; new_balance := v_new;
      return next;
    end if;
  end loop;
end;
$$;
grant execute on function coinsort.recalc_my_balances() to authenticated;

-- Danh sách ví dùng được trong một nhóm: ví chung của nhóm + ví cá nhân của tôi.
create or replace function coinsort.get_group_accounts(p_group_id uuid)
returns setof coinsort.accounts
language sql
security definer
set search_path = coinsort, public, extensions
stable
as $$
  select a.*
  from coinsort.accounts a
  where coalesce(a.status, 'active') = 'active'
    and (
      a.user_id = auth.uid()
      or (a.group_id = p_group_id and exists (
        select 1 from coinsort.group_members gm
        where gm.group_id = p_group_id and gm.user_id = auth.uid() and gm.status = 'active'))
    )
  order by a.group_id nulls last, a.created_at;
$$;
grant execute on function coinsort.get_group_accounts(uuid) to authenticated;

-- Tên ví hiển thị được cho mọi thành viên nhóm (kể cả ví cá nhân của người khác).
-- Chỉ trả về id + tên + loại, KHÔNG trả số dư của ví người khác.
create or replace function coinsort.get_group_account_labels(p_group_id uuid)
returns table (id uuid, name text, account_type text, owner_name text, is_shared boolean)
language sql
security definer
set search_path = coinsort, public, extensions
stable
as $$
  select distinct
    a.id,
    a.name,
    a.account_type,
    coalesce(u.full_name, u.username, '')::text,
    (a.group_id is not null)
  from coinsort.accounts a
  join coinsort.users u on u.id = a.user_id
  where exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = auth.uid() and gm.status = 'active'
  )
  and (
    a.group_id = p_group_id
    or a.id in (
      select t.account_id from coinsort.transactions t where t.group_id = p_group_id
      union
      select t.to_account_id from coinsort.transactions t where t.group_id = p_group_id and t.to_account_id is not null
    )
  );
$$;
grant execute on function coinsort.get_group_account_labels(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Chia tiền
-- ---------------------------------------------------------------------------
alter table coinsort.transactions
  add column if not exists split_mode text default 'none';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'transactions_split_mode_check'
  ) then
    alter table coinsort.transactions
      add constraint transactions_split_mode_check
      check (split_mode in ('none', 'equal', 'exact', 'percent', 'shares'));
  end if;
end $$;

create table if not exists coinsort.transaction_splits (
  transaction_id uuid references coinsort.transactions(id) on delete cascade,
  user_id        uuid references coinsort.users(id) on delete cascade,
  share_amount   numeric not null check (share_amount >= 0),
  primary key (transaction_id, user_id)
);

alter table coinsort.transaction_splits enable row level security;
drop policy if exists "Members manage splits of their group" on coinsort.transaction_splits;
create policy "Members manage splits of their group"
  on coinsort.transaction_splits for all
  using (exists (
    select 1 from coinsort.transactions t
    join coinsort.group_members gm
      on gm.group_id = t.group_id and gm.user_id = auth.uid() and gm.status = 'active'
    where t.id = transaction_splits.transaction_id
  ))
  with check (exists (
    select 1 from coinsort.transactions t
    join coinsort.group_members gm
      on gm.group_id = t.group_id and gm.user_id = auth.uid() and gm.status = 'active'
    where t.id = transaction_splits.transaction_id
  ));

-- ---------------------------------------------------------------------------
-- 3. Quyết toán
-- ---------------------------------------------------------------------------
create table if not exists coinsort.group_settlements (
  id         uuid default uuid_generate_v4() primary key,
  group_id   uuid references coinsort.groups(id) on delete cascade not null,
  from_user  uuid references coinsort.users(id) on delete cascade not null,
  to_user    uuid references coinsort.users(id) on delete cascade not null,
  amount     numeric not null check (amount > 0),
  note       text,
  settled_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_by uuid references coinsort.users(id) on delete set null,
  row_status text check (row_status in ('active', 'deleted')) default 'active',
  check (from_user <> to_user)
);

alter table coinsort.group_settlements enable row level security;
drop policy if exists "Members manage settlements" on coinsort.group_settlements;
create policy "Members manage settlements"
  on coinsort.group_settlements for all
  using (exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = group_settlements.group_id
      and gm.user_id = auth.uid() and gm.status = 'active'))
  with check (exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = group_settlements.group_id
      and gm.user_id = auth.uid() and gm.status = 'active'));

-- ---------------------------------------------------------------------------
-- 4. Mã mời nhóm (thay cho việc vào nhóm chỉ bằng UUID)
-- ---------------------------------------------------------------------------
alter table coinsort.groups
  add column if not exists invite_code text;

create or replace function coinsort.gen_invite_code()
returns text
language plpgsql
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- bỏ I,O,0,1 dễ nhầm
  v_code text := '';
  i integer;
begin
  for i in 1..8 loop
    v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
  end loop;
  return v_code;
end;
$$;

-- Cấp mã cho các nhóm đã có
update coinsort.groups
set invite_code = coinsort.gen_invite_code()
where invite_code is null and is_personal = false;

create unique index if not exists groups_invite_code_key
  on coinsort.groups (invite_code) where invite_code is not null;

commit;

-- =============================================================================
-- 5. RPC — ghi giao dịch nguyên tử (kèm phần chia)
-- =============================================================================

create or replace function coinsort._assert_group_member(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = auth.uid() and gm.status = 'active'
  ) then
    raise exception 'Bạn không thuộc nhóm này';
  end if;
end;
$$;

-- Kiểm tra ví dùng được trong nhóm: ví của chính mình, hoặc ví chung của nhóm.
create or replace function coinsort._assert_account_usable(p_account_id uuid, p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  if p_account_id is null then return; end if;
  if not exists (
    select 1 from coinsort.accounts a
    where a.id = p_account_id
      and coalesce(a.status, 'active') = 'active'
      and (a.user_id = auth.uid() or a.group_id = p_group_id)
  ) then
    raise exception 'Ví không hợp lệ hoặc không thuộc quyền sử dụng của bạn';
  end if;
end;
$$;

-- Ghi phần chia. p_splits dạng [{"user_id": "...", "share_amount": 123}, ...]
create or replace function coinsort._write_splits(
  p_transaction_id uuid,
  p_group_id       uuid,
  p_split_mode     text,
  p_amount         numeric,
  p_splits         jsonb
)
returns void
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_total numeric := 0;
  v_count integer;
begin
  delete from coinsort.transaction_splits where transaction_id = p_transaction_id;

  if p_split_mode is null or p_split_mode = 'none' or p_splits is null then
    return;
  end if;

  -- Mọi người được chia phải là thành viên đang hoạt động của nhóm
  select count(*) into v_count
  from jsonb_array_elements(p_splits) s
  where not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id
      and gm.user_id = (s->>'user_id')::uuid
      and gm.status = 'active'
  );
  if v_count > 0 then
    raise exception 'Có người trong danh sách chia không thuộc nhóm';
  end if;

  insert into coinsort.transaction_splits (transaction_id, user_id, share_amount)
  select p_transaction_id, (s->>'user_id')::uuid, (s->>'share_amount')::numeric
  from jsonb_array_elements(p_splits) s
  where (s->>'share_amount')::numeric > 0;

  select coalesce(sum(share_amount), 0) into v_total
  from coinsort.transaction_splits where transaction_id = p_transaction_id;

  -- Cho phép lệch 1 đơn vị tiền do làm tròn khi chia đều
  if abs(v_total - p_amount) > 1 then
    raise exception 'Tổng phần chia (%) không khớp số tiền giao dịch (%)', v_total, p_amount;
  end if;
end;
$$;

create or replace function coinsort.create_transaction(
  p_group_id         uuid,
  p_account_id       uuid,
  p_type             text,
  p_amount           numeric,
  p_transaction_date timestamptz,
  p_to_account_id    uuid    default null,
  p_category_id      uuid    default null,
  p_fee_amount       numeric default 0,
  p_note             text    default null,
  p_payee            text    default null,
  p_image_url        text    default null,
  p_paid_by          uuid    default null,
  p_split_mode       text    default 'none',
  p_splits           jsonb   default null
)
returns coinsort.transactions
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_row     coinsort.transactions;
  v_paid_by uuid;
begin
  perform coinsort._assert_group_member(p_group_id);

  if p_amount is null or p_amount <= 0 then
    raise exception 'Số tiền phải lớn hơn 0';
  end if;
  if p_type not in ('income', 'expense', 'transfer') then
    raise exception 'Loại giao dịch không hợp lệ';
  end if;
  if p_type = 'transfer' then
    if p_to_account_id is null then
      raise exception 'Chuyển khoản cần ví đích';
    end if;
    if p_to_account_id = p_account_id then
      raise exception 'Ví nguồn và ví đích phải khác nhau';
    end if;
  end if;

  perform coinsort._assert_account_usable(p_account_id, p_group_id);
  perform coinsort._assert_account_usable(p_to_account_id, p_group_id);

  v_paid_by := coalesce(p_paid_by, auth.uid());
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = v_paid_by and gm.status = 'active'
  ) then
    raise exception 'Người trả tiền không thuộc nhóm';
  end if;

  insert into coinsort.transactions (
    group_id, account_id, to_account_id, category_id, type, amount, fee_amount,
    transaction_date, note, payee, image_url, created_by, paid_by, split_mode
  ) values (
    p_group_id, p_account_id, p_to_account_id,
    case when p_type = 'transfer' then null else p_category_id end,
    p_type, p_amount, coalesce(p_fee_amount, 0),
    p_transaction_date, p_note, p_payee, p_image_url,
    auth.uid(), v_paid_by,
    case when p_type = 'expense' then coalesce(p_split_mode, 'none') else 'none' end
  )
  returning * into v_row;

  if p_type = 'expense' then
    perform coinsort._write_splits(v_row.id, p_group_id, p_split_mode, p_amount, p_splits);
  end if;

  return v_row;
end;
$$;
grant execute on function coinsort.create_transaction(uuid, uuid, text, numeric, timestamptz, uuid, uuid, numeric, text, text, text, uuid, text, jsonb) to authenticated;

create or replace function coinsort.update_transaction(
  p_transaction_id   uuid,
  p_account_id       uuid    default null,
  p_to_account_id    uuid    default null,
  p_category_id      uuid    default null,
  p_amount           numeric default null,
  p_transaction_date timestamptz default null,
  p_fee_amount       numeric default null,
  p_note             text    default null,
  p_payee            text    default null,
  p_image_url        text    default null,
  p_paid_by          uuid    default null,
  p_split_mode       text    default null,
  p_splits           jsonb   default null
)
returns coinsort.transactions
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_old coinsort.transactions;
  v_new coinsort.transactions;
begin
  select * into v_old from coinsort.transactions where id = p_transaction_id;
  if not found then raise exception 'Không tìm thấy giao dịch'; end if;
  if coalesce(v_old.row_status, 'active') <> 'active' then
    raise exception 'Giao dịch đã bị xoá';
  end if;

  perform coinsort._assert_group_member(v_old.group_id);

  if p_amount is not null and p_amount <= 0 then
    raise exception 'Số tiền phải lớn hơn 0';
  end if;

  perform coinsort._assert_account_usable(p_account_id, v_old.group_id);
  perform coinsort._assert_account_usable(p_to_account_id, v_old.group_id);

  if p_paid_by is not null and not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = v_old.group_id and gm.user_id = p_paid_by and gm.status = 'active'
  ) then
    raise exception 'Người trả tiền không thuộc nhóm';
  end if;

  update coinsort.transactions t
     set account_id       = coalesce(p_account_id, t.account_id),
         to_account_id    = case when t.type = 'transfer'
                                 then coalesce(p_to_account_id, t.to_account_id)
                                 else null end,
         category_id      = case when t.type = 'transfer'
                                 then null
                                 else coalesce(p_category_id, t.category_id) end,
         amount           = coalesce(p_amount, t.amount),
         transaction_date = coalesce(p_transaction_date, t.transaction_date),
         fee_amount       = coalesce(p_fee_amount, t.fee_amount),
         note             = coalesce(p_note, t.note),
         payee            = coalesce(p_payee, t.payee),
         image_url        = coalesce(p_image_url, t.image_url),
         paid_by          = coalesce(p_paid_by, t.paid_by),
         split_mode       = case when t.type = 'expense'
                                 then coalesce(p_split_mode, t.split_mode)
                                 else 'none' end
   where t.id = p_transaction_id
   returning * into v_new;

  if v_new.type = 'expense' and p_split_mode is not null then
    perform coinsort._write_splits(v_new.id, v_new.group_id, p_split_mode, v_new.amount, p_splits);
  elsif v_new.type = 'expense' and p_amount is not null then
    -- Số tiền đổi mà không gửi phần chia mới → chia lại đều cho những người cũ
    if exists (select 1 from coinsort.transaction_splits where transaction_id = v_new.id) then
      update coinsort.transaction_splits s
         set share_amount = round(v_new.amount / (
               select count(*) from coinsort.transaction_splits where transaction_id = v_new.id))
       where s.transaction_id = v_new.id;
    end if;
  end if;

  return v_new;
end;
$$;
grant execute on function coinsort.update_transaction(uuid, uuid, uuid, uuid, numeric, timestamptz, numeric, text, text, text, uuid, text, jsonb) to authenticated;

-- =============================================================================
-- 6. RPC — số dư nợ trong nhóm và quyết toán
-- =============================================================================

-- net > 0: nhóm đang nợ người này. net < 0: người này đang nợ nhóm.
create or replace function coinsort.get_group_balances(p_group_id uuid)
returns table (
  user_id     uuid,
  full_name   text,
  username    text,
  avatar_url  text,
  paid        numeric,
  owed        numeric,
  settled_out numeric,
  settled_in  numeric,
  net         numeric
)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
begin
  perform coinsort._assert_group_member(p_group_id);

  return query
  with members as (
    select gm.user_id as uid, u.full_name as fname, u.username as uname, u.avatar_url as avatar
    from coinsort.group_members gm
    join coinsort.users u on u.id = gm.user_id
    where gm.group_id = p_group_id and gm.status = 'active'
  ),
  paid_agg as (
    select t.paid_by as uid, sum(t.amount) as total
    from coinsort.transactions t
    where t.group_id = p_group_id
      and t.type = 'expense'
      and coalesce(t.row_status, 'active') = 'active'
      and coalesce(t.split_mode, 'none') <> 'none'
    group by t.paid_by
  ),
  owed_agg as (
    select s.user_id as uid, sum(s.share_amount) as total
    from coinsort.transaction_splits s
    join coinsort.transactions t on t.id = s.transaction_id
    where t.group_id = p_group_id
      and coalesce(t.row_status, 'active') = 'active'
    group by s.user_id
  ),
  out_agg as (
    select gs.from_user as uid, sum(gs.amount) as total
    from coinsort.group_settlements gs
    where gs.group_id = p_group_id and coalesce(gs.row_status, 'active') = 'active'
    group by gs.from_user
  ),
  in_agg as (
    select gs.to_user as uid, sum(gs.amount) as total
    from coinsort.group_settlements gs
    where gs.group_id = p_group_id and coalesce(gs.row_status, 'active') = 'active'
    group by gs.to_user
  )
  select
    m.uid,
    m.fname,
    m.uname,
    m.avatar,
    coalesce(p.total, 0)::numeric,
    coalesce(o.total, 0)::numeric,
    coalesce(so.total, 0)::numeric,
    coalesce(si.total, 0)::numeric,
    (coalesce(p.total, 0) + coalesce(so.total, 0)
     - coalesce(o.total, 0) - coalesce(si.total, 0))::numeric
  from members m
  left join paid_agg p  on p.uid  = m.uid
  left join owed_agg o  on o.uid  = m.uid
  left join out_agg  so on so.uid = m.uid
  left join in_agg   si on si.uid = m.uid
  order by 9 desc;
end;
$$;
grant execute on function coinsort.get_group_balances(uuid) to authenticated;

create or replace function coinsort.settle_up(
  p_group_id uuid,
  p_to_user  uuid,
  p_amount   numeric,
  p_note     text default null
)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  perform coinsort._assert_group_member(p_group_id);

  if p_amount is null or p_amount <= 0 then return 'Số tiền phải lớn hơn 0'; end if;
  if p_to_user = auth.uid() then return 'Không thể quyết toán với chính mình'; end if;
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = p_to_user and gm.status = 'active'
  ) then
    return 'Người nhận không thuộc nhóm';
  end if;

  insert into coinsort.group_settlements (group_id, from_user, to_user, amount, note, created_by)
  values (p_group_id, auth.uid(), p_to_user, p_amount, p_note, auth.uid());
  return '';
end;
$$;
grant execute on function coinsort.settle_up(uuid, uuid, numeric, text) to authenticated;

create or replace function coinsort.get_group_settlements(p_group_id uuid)
returns table (
  id uuid, from_user uuid, from_name text, to_user uuid, to_name text,
  amount numeric, note text, settled_at timestamptz
)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
begin
  perform coinsort._assert_group_member(p_group_id);
  return query
  select gs.id, gs.from_user,
         coalesce(uf.full_name, uf.username, '')::text,
         gs.to_user,
         coalesce(ut.full_name, ut.username, '')::text,
         gs.amount, gs.note, gs.settled_at
  from coinsort.group_settlements gs
  join coinsort.users uf on uf.id = gs.from_user
  join coinsort.users ut on ut.id = gs.to_user
  where gs.group_id = p_group_id and coalesce(gs.row_status, 'active') = 'active'
  order by gs.settled_at desc;
end;
$$;
grant execute on function coinsort.get_group_settlements(uuid) to authenticated;

-- Phần chia của một danh sách giao dịch (để hiển thị trong Records / Edit).
create or replace function coinsort.get_splits_for_group(p_group_id uuid)
returns table (transaction_id uuid, user_id uuid, display_name text, share_amount numeric)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
begin
  perform coinsort._assert_group_member(p_group_id);
  return query
  select s.transaction_id, s.user_id,
         coalesce(u.full_name, u.username, '')::text,
         s.share_amount
  from coinsort.transaction_splits s
  join coinsort.transactions t on t.id = s.transaction_id
  join coinsort.users u on u.id = s.user_id
  where t.group_id = p_group_id and coalesce(t.row_status, 'active') = 'active';
end;
$$;
grant execute on function coinsort.get_splits_for_group(uuid) to authenticated;

-- =============================================================================
-- 7. Siết quyền nhóm
-- =============================================================================

-- Bỏ policy cho phép chèn nhóm tuỳ ý. Việc tạo nhóm đi qua RPC create_group
-- (security definer) nên không cần policy INSERT mở.
drop policy if exists "Users can insert groups" on coinsort.groups;

-- Tạo nhóm: sinh kèm mã mời.
create or replace function coinsort.create_group(p_name text)
returns setof coinsort.groups
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  new_id uuid;
  v_code text;
begin
  if auth.uid() is null then raise exception 'Chưa đăng nhập'; end if;
  if trim(coalesce(p_name, '')) = '' then raise exception 'Tên nhóm không được trống'; end if;

  loop
    v_code := coinsort.gen_invite_code();
    exit when not exists (select 1 from coinsort.groups where invite_code = v_code);
  end loop;

  insert into coinsort.groups (name, is_personal, status, invite_code)
  values (trim(p_name), false, 'active', v_code)
  returning id into new_id;

  insert into coinsort.group_members (group_id, user_id, role, status)
  values (new_id, auth.uid(), 'admin', 'active');

  return query select * from coinsort.groups where id = new_id;
end;
$$;
grant execute on function coinsort.create_group(text) to authenticated;

-- Vào nhóm bằng mã mời (thay cho việc chỉ cần biết UUID).
create or replace function coinsort.join_group_by_code(p_code text)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  g record;
begin
  if auth.uid() is null then return 'Chưa đăng nhập'; end if;
  select id, is_personal into g
  from coinsort.groups
  where upper(trim(invite_code)) = upper(trim(coalesce(p_code, '')))
    and status = 'active';
  if not found then return 'Mã mời không đúng hoặc đã hết hiệu lực'; end if;
  if g.is_personal then return 'Không thể tham gia nhóm cá nhân'; end if;

  insert into coinsort.group_members (group_id, user_id, role, status)
  values (g.id, auth.uid(), 'member', 'active')
  on conflict (group_id, user_id) do update set status = 'active';
  return '';
end;
$$;
grant execute on function coinsort.join_group_by_code(text) to authenticated;

-- Vào nhóm bằng UUID: giữ lại nhưng CHẶN. Ai biết UUID không đương nhiên
-- được vào nhóm — phải có mã mời hoặc lời mời từ admin.
create or replace function coinsort.join_group(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  return 'Cần mã mời để tham gia nhóm. Hãy xin mã từ quản trị viên nhóm.';
end;
$$;

-- Đổi mã mời (chỉ admin).
create or replace function coinsort.rotate_invite_code(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  v_code text;
begin
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = auth.uid()
      and gm.role = 'admin' and gm.status = 'active'
  ) then
    raise exception 'Chỉ quản trị viên mới đổi được mã mời';
  end if;
  loop
    v_code := coinsort.gen_invite_code();
    exit when not exists (select 1 from coinsort.groups where invite_code = v_code);
  end loop;
  update coinsort.groups set invite_code = v_code where id = p_group_id;
  return v_code;
end;
$$;
grant execute on function coinsort.rotate_invite_code(uuid) to authenticated;

-- Chuyển quyền quản trị.
create or replace function coinsort.transfer_admin(p_group_id uuid, p_user_id uuid)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
begin
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = auth.uid()
      and gm.role = 'admin' and gm.status = 'active'
  ) then
    return 'Chỉ quản trị viên mới chuyển được quyền';
  end if;
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = p_user_id and gm.status = 'active'
  ) then
    return 'Người này không thuộc nhóm';
  end if;
  update coinsort.group_members set role = 'admin'
   where group_id = p_group_id and user_id = p_user_id;
  return '';
end;
$$;
grant execute on function coinsort.transfer_admin(uuid, uuid) to authenticated;

-- Xoá nhóm: trả lỗi thật thay vì im lặng thành công.
create or replace function coinsort.delete_group(p_group_id uuid)
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
  if g.is_personal then return 'Không thể xoá nhóm cá nhân'; end if;
  if not exists (
    select 1 from coinsort.group_members gm
    where gm.group_id = p_group_id and gm.user_id = auth.uid()
      and gm.role = 'admin' and gm.status = 'active'
  ) then
    return 'Chỉ quản trị viên mới xoá được nhóm';
  end if;
  update coinsort.groups set status = 'deleted' where id = p_group_id;
  return '';
end;
$$;
grant execute on function coinsort.delete_group(uuid) to authenticated;

-- Mã mời chỉ hiện cho thành viên (get_user_groups đã lọc theo thành viên).
create or replace function coinsort.get_user_groups()
returns setof coinsort.groups
language sql
security definer
set search_path = coinsort, public, extensions
stable
as $$
  select g.* from coinsort.groups g
  inner join coinsort.group_members gm
    on gm.group_id = g.id and gm.user_id = auth.uid() and gm.status = 'active'
  where g.status = 'active'
  order by g.is_personal desc, g.created_at;
$$;
grant execute on function coinsort.get_user_groups() to authenticated;

-- Giới hạn tần suất tìm người dùng: tối thiểu 3 ký tự, tối đa 20 kết quả.
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
  if auth.uid() is null then return; end if;
  q := trim(coalesce(p_query, ''));
  if length(q) < 3 then return; end if;
  q := '%' || replace(replace(q, '\', '\\'), '%', '\%') || '%';
  return query
  select u.id, u.username, u.full_name, u.avatar_url
  from coinsort.users u
  where u.status = 'active'
    and u.id <> auth.uid()
    and (u.username ilike q escape '\' or u.full_name ilike q escape '\')
  order by u.username nulls last, u.full_name nulls last
  limit 20;
end;
$$;
grant execute on function coinsort.search_users(text) to authenticated;


-- ############################################################################
-- ## migrations/003_indexes_and_analytics.sql
-- ############################################################################

-- =============================================================================
-- MIGRATION 003 — Index và gộp tính toán về server (Giai đoạn 3)
--
-- Chạy SAU 002_group_splits.sql. Idempotent.
--
-- Sửa:
--   - Không có index nào trên schema → truy vấn nóng nhất quét toàn bảng.
--   - Màn Biểu đồ tải toàn bộ giao dịch 4 lần rồi tính lại phía client.
--   - limit 500 gắn cứng, không phân trang.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Index
-- ---------------------------------------------------------------------------
-- Truy vấn nóng nhất: danh sách giao dịch của một nhóm theo thời gian giảm dần.
create index if not exists idx_transactions_group_date
  on coinsort.transactions (group_id, transaction_date desc)
  where row_status = 'active' or row_status is null;

create index if not exists idx_transactions_account      on coinsort.transactions (account_id);
create index if not exists idx_transactions_to_account   on coinsort.transactions (to_account_id) where to_account_id is not null;
create index if not exists idx_transactions_category     on coinsort.transactions (category_id)   where category_id is not null;
create index if not exists idx_transactions_paid_by      on coinsort.transactions (paid_by);

create index if not exists idx_group_members_user        on coinsort.group_members (user_id, status);
create index if not exists idx_group_members_group       on coinsort.group_members (group_id, status);

create index if not exists idx_accounts_user             on coinsort.accounts (user_id, status);
create index if not exists idx_accounts_group            on coinsort.accounts (group_id) where group_id is not null;

create index if not exists idx_categories_user           on coinsort.categories (user_id, type, order_index);
create index if not exists idx_splits_user               on coinsort.transaction_splits (user_id);
create index if not exists idx_settlements_group         on coinsort.group_settlements (group_id);
create index if not exists idx_invitations_user          on coinsort.group_invitations (user_id, status);
create index if not exists idx_audit_transaction         on coinsort.transaction_audit (transaction_id, changed_at desc);

create index if not exists idx_budgets_user              on coinsort.budgets (user_id, status);
create index if not exists idx_recurring_next            on coinsort.recurring_transactions (next_date) where is_active = true;

-- Tìm kiếm ghi chú / người nhận
create index if not exists idx_transactions_note_trgm
  on coinsort.transactions using gin (note gin_trgm_ops);
-- Nếu extension chưa bật, chạy trước: create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------------
-- 2. Gộp tính toán biểu đồ: một lượt gọi thay cho bốn
-- ---------------------------------------------------------------------------
create or replace function coinsort.get_analytics(
  p_group_id    uuid,
  p_from        timestamptz default null,
  p_to          timestamptz default null,
  p_account_ids uuid[]      default null,
  p_top_limit   integer     default 5
)
returns jsonb
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
declare
  v_result jsonb;
begin
  perform coinsort._assert_group_member(p_group_id);

  with scoped as (
    select t.*
    from coinsort.transactions t
    where t.group_id = p_group_id
      and coalesce(t.row_status, 'active') = 'active'
      and (p_from is null or t.transaction_date >= p_from)
      and (p_to   is null or t.transaction_date <= p_to)
      and (p_account_ids is null or t.account_id = any(p_account_ids))
  ),
  by_cat as (
    select
      s.type,
      coalesce(c.name, 'Khác')      as name,
      coalesce(c.color_hex, '#A0A0A0') as color_hex,
      coalesce(c.icon_name, 'category') as icon_name,
      sum(s.amount)                 as amount
    from scoped s
    left join coinsort.categories c on c.id = s.category_id
    where s.type in ('income', 'expense')
    group by s.type, c.name, c.color_hex, c.icon_name
  ),
  top_tx as (
    select s.type, s.id, s.amount, s.transaction_date, s.note,
           coalesce(c.name, 'Khác') as category_name,
           coalesce(c.color_hex, '#A0A0A0') as color_hex,
           row_number() over (partition by s.type order by s.amount desc) as rn
    from scoped s
    left join coinsort.categories c on c.id = s.category_id
    where s.type in ('income', 'expense')
  )
  select jsonb_build_object(
    'expense_total', coalesce((select sum(amount) from by_cat where type = 'expense'), 0),
    'income_total',  coalesce((select sum(amount) from by_cat where type = 'income'), 0),
    'expense_by_category', coalesce((
      select jsonb_agg(jsonb_build_object(
               'name', name, 'amount', amount, 'color_hex', color_hex, 'icon_name', icon_name)
             order by amount desc)
      from by_cat where type = 'expense'), '[]'::jsonb),
    'income_by_category', coalesce((
      select jsonb_agg(jsonb_build_object(
               'name', name, 'amount', amount, 'color_hex', color_hex, 'icon_name', icon_name)
             order by amount desc)
      from by_cat where type = 'income'), '[]'::jsonb),
    'top_expense', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', id, 'amount', amount, 'transaction_date', transaction_date,
               'note', note, 'category_name', category_name, 'color_hex', color_hex)
             order by amount desc)
      from top_tx where type = 'expense' and rn <= p_top_limit), '[]'::jsonb),
    'top_income', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', id, 'amount', amount, 'transaction_date', transaction_date,
               'note', note, 'category_name', category_name, 'color_hex', color_hex)
             order by amount desc)
      from top_tx where type = 'income' and rn <= p_top_limit), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;
grant execute on function coinsort.get_analytics(uuid, timestamptz, timestamptz, uuid[], integer) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Tổng thu/chi trong kỳ (cho thẻ tóm tắt màn Giao dịch) — không cần tải list
-- ---------------------------------------------------------------------------
create or replace function coinsort.get_period_summary(
  p_group_id    uuid,
  p_from        timestamptz default null,
  p_to          timestamptz default null,
  p_account_ids uuid[]      default null
)
returns table (income numeric, expense numeric, tx_count bigint)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
begin
  perform coinsort._assert_group_member(p_group_id);
  return query
  select
    coalesce(sum(t.amount) filter (where t.type = 'income'), 0)::numeric,
    coalesce(sum(t.amount) filter (where t.type = 'expense'), 0)::numeric,
    count(*)::bigint
  from coinsort.transactions t
  where t.group_id = p_group_id
    and coalesce(t.row_status, 'active') = 'active'
    and (p_from is null or t.transaction_date >= p_from)
    and (p_to   is null or t.transaction_date <= p_to)
    and (p_account_ids is null or t.account_id = any(p_account_ids));
end;
$$;
grant execute on function coinsort.get_period_summary(uuid, timestamptz, timestamptz, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Tiến độ ngân sách (Giai đoạn 2 dùng tới)
-- ---------------------------------------------------------------------------
create or replace function coinsort.get_budget_progress(p_group_id uuid)
returns table (
  budget_id     uuid,
  category_id   uuid,
  category_name text,
  color_hex     text,
  icon_name     text,
  amount        numeric,
  spent         numeric,
  period        text,
  start_date    date,
  end_date      date
)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
begin
  return query
  select
    b.id, b.category_id,
    coalesce(c.name, 'Khác')::text,
    coalesce(c.color_hex, '#A0A0A0')::text,
    coalesce(c.icon_name, 'category')::text,
    b.amount,
    coalesce((
      select sum(t.amount) from coinsort.transactions t
      where t.group_id = p_group_id
        and t.category_id = b.category_id
        and t.type = 'expense'
        and coalesce(t.row_status, 'active') = 'active'
        and t.transaction_date >= b.start_date
        and t.transaction_date < (b.end_date + 1)
    ), 0)::numeric,
    b.period, b.start_date, b.end_date
  from coinsort.budgets b
  left join coinsort.categories c on c.id = b.category_id
  where b.user_id = auth.uid()
    and coalesce(b.status, 'active') = 'active'
  order by b.start_date desc;
end;
$$;
grant execute on function coinsort.get_budget_progress(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Sinh giao dịch định kỳ tới hạn (Giai đoạn 2)
-- ---------------------------------------------------------------------------
-- Gọi khi app khởi động, và/hoặc đặt lịch bằng pg_cron:
--   select cron.schedule('recurring-daily', '5 0 * * *',
--                        $cron$ select coinsort.run_due_recurring_all() $cron$);
create or replace function coinsort.run_due_recurring(p_group_id uuid)
returns integer
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  r      record;
  v_made integer := 0;
begin
  perform coinsort._assert_group_member(p_group_id);

  for r in
    select * from coinsort.recurring_transactions
    where user_id = auth.uid()
      and is_active = true
      and coalesce(status, 'active') = 'active'
      and next_date <= current_date
  loop
    -- Bắt kịp mọi kỳ đã bỏ lỡ, không chỉ kỳ gần nhất
    while r.next_date <= current_date loop
      insert into coinsort.transactions (
        group_id, account_id, category_id, type, amount, transaction_date,
        note, created_by, paid_by, split_mode
      ) values (
        p_group_id, r.account_id, r.category_id, r.type, r.amount,
        r.next_date::timestamptz,
        coalesce(r.note, 'Giao dịch định kỳ'),
        r.user_id, r.user_id, 'none'
      );
      v_made := v_made + 1;

      r.next_date := case r.frequency
        when 'daily'   then r.next_date + interval '1 day'
        when 'weekly'  then r.next_date + interval '1 week'
        when 'monthly' then r.next_date + interval '1 month'
        when 'yearly'  then r.next_date + interval '1 year'
      end;
    end loop;

    update coinsort.recurring_transactions
       set next_date = r.next_date
     where id = r.id;
  end loop;

  return v_made;
end;
$$;
grant execute on function coinsort.run_due_recurring(uuid) to authenticated;


-- ############################################################################
-- ## migrations/004_account_deletion_and_storage.sql
-- ############################################################################

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


-- ############################################################################
-- ## migrations/005_security_hardening.sql
-- ############################################################################

-- =============================================================================
-- MIGRATION 005 — Vá lỗ hổng bảo mật RLS/RPC (Giai đoạn 5)
--
-- Chạy SAU 004_account_deletion_and_storage.sql. Idempotent (chạy lại nhiều lần
-- không lỗi). Toàn bộ nằm trong một transaction begin; ... commit;
--
-- Đây là app tài chính: chính xác là tối quan trọng. Migration này KHÔNG đổi
-- logic nghiệp vụ; chỉ siết quyền để không ai chạm được dữ liệu/số dư của người
-- khác qua PostgREST.
--
-- Tóm tắt các mục vá:
--   P0-1  REVOKE execute mọi hàm helper NỘI BỘ khỏi public/anon/authenticated.
--         Mặc định Supabase cho anon/authenticated execute MỌI hàm schema coinsort;
--         apply_balance_delta() (security definer, không tự kiểm quyền) vì thế bị
--         lộ ra ngoài → bất kỳ ai gọi để đặt lại số dư ví người khác.
--   P0-2  transactions: with check khi INSERT/UPDATE phải bảo đảm account_id (và
--         to_account_id) là ví CỦA MÌNH hoặc ví CHUNG của nhóm, created_by là
--         chính mình, paid_by là thành viên nhóm — không cho ghi thẳng vào ví
--         người khác.
--   P0-3  group_settlements: tách policy FOR ALL "chỉ cần là thành viên" thành
--         SELECT (thành viên) + INSERT/UPDATE/DELETE (chỉ from_user/created_by).
--   P0-5  get_email_for_login: bỏ khớp theo full_name (không unique) → chỉ khớp
--         username chính xác hoặc email. Chặn dò email của người khác bằng tên.
--   P1-5  users: thêm policy SELECT cho phép đọc hồ sơ của thành viên CÙNG NHÓM.
--   P2-2  get_budget_progress: thêm _assert_group_member khi có nhóm.
--   P2-3  handle_new_user: bổ sung set search_path = coinsort, public, extensions.
--   P2-4  storage receipts: thêm giới hạn size/MIME ở bucket. KHÔNG nới lỏng
--         SELECT cho thành viên nhóm được vì image_url do client tự đặt và không
--         ràng buộc → xem chi tiết phần P2-4 (cần đổi cách lưu path phía app).
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- P2-3 — handle_new_user: set search_path = coinsort, public, extensions
-- ---------------------------------------------------------------------------
-- Trigger chạy trên auth.users. Thiếu search_path cố định → có thể bị dẫn dụ
-- phân giải tên bảng sai (search_path do phiên đặt). Giữ NGUYÊN thân hàm, chỉ
-- thêm `set search_path = coinsort, public, extensions`. Không đụng tới trigger on_auth_user_created
-- (nó tham chiếu hàm theo tên nên create or replace là đủ).
create or replace function coinsort.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  personal_group_id uuid;
begin
  insert into coinsort.users (id, full_name, avatar_url, username, role, status)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    coalesce(new.raw_user_meta_data->>'username', 'user_' || left(new.id::text, 8)),
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

-- ---------------------------------------------------------------------------
-- P0-5 — get_email_for_login: chỉ khớp username hoặc email
-- ---------------------------------------------------------------------------
-- Hàm này granted cho anon vì luồng đăng nhập gọi khi CHƯA đăng nhập
-- (lib/src/features/auth/data/auth_repository.dart -> signInWithEmailOrUsername).
-- Vì vậy vẫn giữ grant cho anon, nhưng siết logic:
--   * Bỏ hoàn toàn nhánh khớp theo full_name: full_name KHÔNG unique và cho phép
--     kẻ tấn công dò ra email của người khác chỉ bằng tên hiển thị.
--   * Chỉ khớp theo username (cột UNIQUE → tối đa một kết quả) hoặc trả lại chính
--     email nếu người dùng đã nhập email.
--   * Bỏ qua tài khoản đã xoá (status != 'active').
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

  -- Chỉ khớp username chính xác (UNIQUE). KHÔNG khớp theo full_name.
  select u.email into result
  from auth.users u
  inner join coinsort.users p on p.id = u.id
  where p.username = login_id
    and coalesce(p.status, 'active') = 'active'
  limit 1;

  return result;
end;
$$;
-- Luồng đăng nhập chạy ở trạng thái anon nên buộc phải giữ grant cho anon.
grant execute on function coinsort.get_email_for_login(text) to anon;
grant execute on function coinsort.get_email_for_login(text) to authenticated;

-- ---------------------------------------------------------------------------
-- P2-2 — get_budget_progress: kiểm tra thành viên nhóm
-- ---------------------------------------------------------------------------
-- Giữ NGUYÊN toàn bộ logic của migration 003, chỉ thêm _assert_group_member khi
-- p_group_id không null (spent được tính theo giao dịch của nhóm). Ngân sách cá
-- nhân (p_group_id null) không cần kiểm tra nhóm: b.user_id = auth.uid() đã giới
-- hạn về ngân sách của chính người gọi, và điều kiện t.group_id = null không bao
-- giờ khớp nên spent = 0 (giữ đúng hành vi cũ khi truyền null).
create or replace function coinsort.get_budget_progress(p_group_id uuid)
returns table (
  budget_id     uuid,
  category_id   uuid,
  category_name text,
  color_hex     text,
  icon_name     text,
  amount        numeric,
  spent         numeric,
  period        text,
  start_date    date,
  end_date      date
)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
begin
  if p_group_id is not null then
    perform coinsort._assert_group_member(p_group_id);
  end if;

  return query
  select
    b.id, b.category_id,
    coalesce(c.name, 'Khác')::text,
    coalesce(c.color_hex, '#A0A0A0')::text,
    coalesce(c.icon_name, 'category')::text,
    b.amount,
    coalesce((
      select sum(t.amount) from coinsort.transactions t
      where t.group_id = p_group_id
        and t.category_id = b.category_id
        and t.type = 'expense'
        and coalesce(t.row_status, 'active') = 'active'
        and t.transaction_date >= b.start_date
        and t.transaction_date < (b.end_date + 1)
    ), 0)::numeric,
    b.period, b.start_date, b.end_date
  from coinsort.budgets b
  left join coinsort.categories c on c.id = b.category_id
  where b.user_id = auth.uid()
    and coalesce(b.status, 'active') = 'active'
  order by b.start_date desc;
end;
$$;
grant execute on function coinsort.get_budget_progress(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- P1-5 — users: đọc hồ sơ thành viên cùng nhóm
-- ---------------------------------------------------------------------------
-- Hiện users chỉ có "Users can view own profile" (auth.uid() = id) nên khi hiển
-- thị tên/ảnh của thành viên khác phải đi qua RPC. Ta bổ sung một policy SELECT
-- cho phép đọc hồ sơ của user có chung ít nhất một nhóm đang hoạt động với người
-- gọi.
--
-- LƯU Ý KỸ THUẬT: policy SELECT hiện tại của group_members chỉ trả về CHÍNH các
-- dòng của người gọi (user_id = auth.uid()). Nếu viết subquery group_members
-- trực tiếp trong policy của users, RLS của group_members sẽ được áp lên subquery
-- đó và chỉ thấy dòng của chính mình → không bao giờ khớp thành viên khác. Vì vậy
-- ta dùng một hàm SECURITY DEFINER (bỏ qua RLS của group_members) chỉ trả về
-- boolean "hai người có chung nhóm không". Hàm chỉ trả boolean, không lộ dữ liệu
-- nhạy cảm, và bắt buộc để policy hoạt động nên được grant cho authenticated.
create or replace function coinsort.shares_group_with_me(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = coinsort, public, extensions
stable
as $$
  select exists (
    select 1
    from coinsort.group_members gm_me
    join coinsort.group_members gm_them
      on gm_them.group_id = gm_me.group_id
    where gm_me.user_id = auth.uid()
      and gm_me.status = 'active'
      and gm_them.user_id = p_user_id
      and gm_them.status = 'active'
  );
$$;
grant execute on function coinsort.shares_group_with_me(uuid) to authenticated;

drop policy if exists "Users can view group members profiles" on coinsort.users;
create policy "Users can view group members profiles"
  on coinsort.users for select
  using (coinsort.shares_group_with_me(id));
-- Ghi chú: RLS ở mức DÒNG, không giới hạn được theo CỘT. Policy này cho thành
-- viên cùng nhóm đọc cả dòng users (gồm full_name, username, avatar_url, và cả
-- is_premium/role/status — đều không phải bí mật; email KHÔNG nằm ở bảng này mà ở
-- auth.users). Nếu sau này cần giấu cột, phải dùng column privileges hoặc view
-- riêng — ngoài phạm vi bản vá này.

-- ---------------------------------------------------------------------------
-- P0-1 — REVOKE execute các hàm helper NỘI BỘ
-- ---------------------------------------------------------------------------
-- Trong Supabase, mọi hàm schema coinsort MẶC ĐỊNH có execute cho PUBLIC (kéo theo
-- anon + authenticated). Toàn repo trước đây không có một lệnh revoke nào, nên
-- các hàm nội bộ dưới đây bị lộ thẳng ra PostgREST. Đặc biệt apply_balance_delta
-- là security definer và KHÔNG tự kiểm tra quyền → bất kỳ ai cũng gọi được để
-- sửa số dư ví bất kỳ.
--
-- Các hàm này chỉ được gọi TỪ BÊN TRONG các hàm security definer khác (owner là
-- postgres) hoặc từ trigger. Owner vẫn giữ execute; revoke chỉ gỡ quyền của
-- public/anon/authenticated nên KHÔNG phá luồng gọi nội bộ và KHÔNG ảnh hưởng
-- trigger (trigger chạy không cần execute của người gọi). Các RPC mặt tiền mà
-- client cần (create_transaction, update_transaction, settle_up, get_analytics,
-- get_group_balances, delete_my_account, get_email_for_login, ...) KHÔNG bị đụng.
--
-- revoke là idempotent: gỡ một quyền không tồn tại không gây lỗi.

-- Helper sửa số dư — điểm duy nhất được phép chạm accounts.balance.
revoke execute on function coinsort.apply_balance_delta(uuid, numeric) from public, anon, authenticated;

-- Helper nghiệp vụ nhóm/chia tiền (bắt đầu bằng _).
revoke execute on function coinsort._assert_group_member(uuid) from public, anon, authenticated;
revoke execute on function coinsort._assert_account_usable(uuid, uuid) from public, anon, authenticated;
revoke execute on function coinsort._write_splits(uuid, uuid, text, numeric, jsonb) from public, anon, authenticated;

-- Sinh mã mời — chỉ dùng nội bộ trong create_group/rotate_invite_code.
revoke execute on function coinsort.gen_invite_code() from public, anon, authenticated;

-- Hàm trigger (trả về trigger; PostgREST không phơi ra như RPC, nhưng revoke cho
-- chắc chắn — phòng thủ theo chiều sâu). Việc revoke KHÔNG chặn trigger kích hoạt.
revoke execute on function coinsort.update_account_balance() from public, anon, authenticated;
revoke execute on function coinsort.touch_updated_at() from public, anon, authenticated;
revoke execute on function coinsort.log_transaction_change() from public, anon, authenticated;
revoke execute on function coinsort.handle_new_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- P0-2 — transactions: siết with check khi ghi vào ví
-- ---------------------------------------------------------------------------
-- Policy cũ chỉ kiểm tra "là thành viên nhóm" nên một thành viên có thể chèn/sửa
-- giao dịch trỏ account_id vào ví CÁ NHÂN của người khác (không chia sẻ), qua đó
-- làm sai số dư ví đó (trigger update_account_balance sẽ áp delta lên ví bị trỏ).
--
-- Điều kiện ví hợp lệ nhân bản đúng logic _assert_account_usable: ví phải là ví
-- của chính người gọi (a.user_id = auth.uid()) HOẶC ví chung của đúng nhóm giao
-- dịch (a.group_id = transactions.group_id). Kết hợp với điều kiện người gọi là
-- thành viên nhóm nên an toàn tương đương RPC create_transaction/update_transaction.
--
-- Ứng dụng luôn ghi giao dịch QUA RPC (security definer, bỏ qua RLS) nên các
-- policy này chỉ chặn ghi thẳng qua PostgREST — không ảnh hưởng luồng bình thường.
-- created_by và paid_by ở schema là NOT NULL nên không cần nhánh null.

drop policy if exists "Users can insert group transactions" on coinsort.transactions;
create policy "Users can insert group transactions"
  on coinsort.transactions for insert
  with check (
    -- (a) người ghi là thành viên đang hoạt động của nhóm
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
    -- (b) created_by phải là chính người đang đăng nhập
    and transactions.created_by = auth.uid()
    -- (c) ví nguồn phải thuộc quyền dùng: ví của mình HOẶC ví chung của nhóm
    and exists (
      select 1 from coinsort.accounts a
      where a.id = transactions.account_id
        and coalesce(a.status, 'active') = 'active'
        and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
    )
    -- (d) ví đích (transfer) nếu có cũng phải hợp lệ
    and (
      transactions.to_account_id is null
      or exists (
        select 1 from coinsort.accounts a
        where a.id = transactions.to_account_id
          and coalesce(a.status, 'active') = 'active'
          and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
      )
    )
    -- (e) paid_by phải là thành viên nhóm
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = transactions.paid_by
        and gm.status = 'active'
    )
  );

drop policy if exists "Users can update group transactions" on coinsort.transactions;
create policy "Users can update group transactions"
  on coinsort.transactions for update
  using (
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  )
  with check (
    -- vẫn là giao dịch của nhóm mình
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
    -- ví nguồn sau khi sửa vẫn phải thuộc quyền dùng
    and exists (
      select 1 from coinsort.accounts a
      where a.id = transactions.account_id
        and coalesce(a.status, 'active') = 'active'
        and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
    )
    -- ví đích (transfer) nếu có cũng phải hợp lệ
    and (
      transactions.to_account_id is null
      or exists (
        select 1 from coinsort.accounts a
        where a.id = transactions.to_account_id
          and coalesce(a.status, 'active') = 'active'
          and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
      )
    )
    -- paid_by vẫn phải là thành viên nhóm
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = transactions.paid_by
        and gm.status = 'active'
    )
  );
-- Policy SELECT ("Users can view group transactions") và DELETE ("Users can
-- delete group transactions") giữ nguyên: chúng chỉ cho thành viên xem/xoá giao
-- dịch của nhóm mình, không mở đường ghi vào ví người khác.

-- ---------------------------------------------------------------------------
-- P0-3 — group_settlements: chống giả mạo quyết toán
-- ---------------------------------------------------------------------------
-- Policy cũ FOR ALL chỉ kiểm tra "là thành viên nhóm" → một thành viên bất kỳ có
-- thể chèn quyết toán mạo danh (from_user là người khác) hoặc sửa/xoá quyết toán
-- của người khác, làm sai công nợ. Tách thành các policy theo thao tác:
--   SELECT  : mọi thành viên nhóm xem được.
--   INSERT  : chỉ tạo được bản ghi mà from_user = mình (và created_by = mình).
--   UPDATE  : chỉ người tạo/from_user sửa được, và không đổi được sang người khác.
--   DELETE  : chỉ người tạo/from_user xoá được.
-- Ứng dụng ghi quyết toán qua RPC settle_up (security definer, bỏ qua RLS) và đọc
-- qua get_group_settlements nên siết RLS không ảnh hưởng luồng thường.
drop policy if exists "Members manage settlements" on coinsort.group_settlements;

drop policy if exists "Members can view settlements" on coinsort.group_settlements;
create policy "Members can view settlements"
  on coinsort.group_settlements for select
  using (
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

drop policy if exists "Members can create own settlements" on coinsort.group_settlements;
create policy "Members can create own settlements"
  on coinsort.group_settlements for insert
  with check (
    group_settlements.from_user = auth.uid()
    and (group_settlements.created_by is null or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

drop policy if exists "Creators can update own settlements" on coinsort.group_settlements;
create policy "Creators can update own settlements"
  on coinsort.group_settlements for update
  using (
    (group_settlements.from_user = auth.uid() or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  )
  with check (
    group_settlements.from_user = auth.uid()
    and (group_settlements.created_by is null or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

drop policy if exists "Creators can delete own settlements" on coinsort.group_settlements;
create policy "Creators can delete own settlements"
  on coinsort.group_settlements for delete
  using (
    (group_settlements.from_user = auth.uid() or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

-- ---------------------------------------------------------------------------
-- P2-4 — storage receipts: giới hạn size/MIME (+ ghi chú giới hạn an toàn)
-- ---------------------------------------------------------------------------
-- 1) Ràng buộc size/MIME ở BUCKET (Supabase hỗ trợ qua storage.buckets). Khớp với
--    giới hạn 5MB và các định dạng ảnh mà app dùng (jpeg/png/webp/heic).
update storage.buckets
   set file_size_limit = 5242880,  -- 5 MB, khớp StorageService.maxBytes phía app
       allowed_mime_types = array['image/jpeg','image/png','image/webp','image/heic','image/heif']
 where id = 'receipts';

update storage.buckets
   set file_size_limit = 5242880,
       allowed_mime_types = array['image/jpeg','image/png','image/webp','image/heic','image/heif']
 where id = 'avatars';

-- 2) KHÔNG nới lỏng SELECT cho thành viên nhóm — CỐ Ý GIỮ NGUYÊN policy per-UID
--    "Users manage own receipts" của migration 004.
--
--    Vì sao không thể vá an toàn bằng SQL thuần:
--    - App lưu ảnh hoá đơn tại path "{uid}/{timestamp}.{ext}" và ghi CHÍNH path
--      đó (chuỗi tuỳ ý do client đặt) vào transactions.image_url.
--    - Một policy kiểu "cho đọc object nếu tồn tại transaction cùng nhóm có
--      image_url = storage.objects.name" NGHE có vẻ đúng nhưng TẠO LỖ HỔNG MỚI:
--      image_url do client đặt và KHÔNG bị ràng buộc phải khớp chủ sở hữu path.
--      Kẻ tấn công chỉ cần tạo một giao dịch trong nhóm của MÌNH với
--      image_url = "victimUID/....jpg" là mượn được quyền đọc hoá đơn của nạn
--      nhân (IDOR) — kể cả khi nạn nhân không ở trong nhóm đó.
--    - Do đó, theo nguyên tắc "thà giữ nguyên còn hơn mở toang", ta KHÔNG thêm
--      policy nới lỏng ở đây.
--
--    CẦN LÀM PHÍA APP (ngoài phạm vi file SQL này — việc của Dart):
--      * Đổi cách lưu path hoá đơn của giao dịch NHÓM sang theo nhóm, ví dụ
--        "receipts/{group_id}/{uid}/{timestamp}.{ext}", rồi mới thêm policy
--        SELECT trên storage.objects với điều kiện
--        (storage.foldername(name))[1] = group_id và người gọi là thành viên
--        active của group_id đó. Khi ấy quyền đọc gắn với NHÓM trong chính path
--        (không bịa được), an toàn để chia sẻ.
--      * Hoặc thêm cột riêng ánh xạ object -> transaction do server kiểm soát,
--        và chặn client tự đặt image_url trỏ tới path của người khác.
--    Trước khi làm được điều đó, hoá đơn của giao dịch nhóm chỉ người tải lên xem
--    được (đúng như hành vi hiện tại) — an toàn nhưng chưa chia sẻ được.

commit;


-- ############################################################################
-- ## migrations/006_account_deletion_fix.sql
-- ############################################################################

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


-- ############################################################################
-- ## migrations/007_account_deletion_free_email.sql
-- ############################################################################

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


-- ############################################################################
-- ## migrations/008_social_auth_and_username_only.sql
-- ############################################################################

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


-- ############################################################################
-- ## seed.sql
-- ############################################################################

-- =============================================================================
-- SEED: Danh mục mặc định (hệ thống). Chạy trong Supabase SQL Editor sau schema.sql.
-- =============================================================================

-- Xóa danh mục cũ (user_id null) để seed lại bộ mới
delete from coinsort.categories where user_id is null;

-- HỆ THỐNG DANH MỤC CHI TIÊU (Expense)
INSERT INTO coinsort.categories (name, type, icon_name, color_hex, is_default, order_index) VALUES
  ('Food & Dining', 'expense', 'restaurant', '#FFD700', true, 1),
  ('Health', 'expense', 'medical_services', '#4169E1', true, 2),
  ('Beauty', 'expense', 'face', '#FF69B4', true, 3),
  ('Job', 'expense', 'work', '#32CD32', true, 4),
  ('Shopping', 'expense', 'shopping_cart', '#FFA500', true, 5),
  ('Transportation', 'expense', 'directions_car', '#8A2BE2', true, 6),
  ('Housing', 'expense', 'home', '#20B2AA', true, 7),
  ('Entertainment', 'expense', 'sports_esports', '#FF4500', true, 8),
  ('Education', 'expense', 'school', '#4682B4', true, 9),
  ('Sports', 'expense', 'pool', '#00FA9A', true, 10),
  ('Social', 'expense', 'people', '#FF8C00', true, 11),
  ('Clothing', 'expense', 'checkroom', '#DDA0DD', true, 12),
  ('Car', 'expense', 'directions_car_filled', '#708090', true, 13),
  ('Electronics', 'expense', 'devices', '#696969', true, 14),
  ('Travel', 'expense', 'flight_takeoff', '#00BFFF', true, 15),
  ('Pets', 'expense', 'pets', '#8B4513', true, 16),
  ('Gifts', 'expense', 'card_giftcard', '#FF1493', true, 17),
  ('Donations', 'expense', 'volunteer_activism', '#FF6347', true, 18),
  ('Family', 'expense', 'family_restroom', '#2E8B57', true, 19);

-- HỆ THỐNG DANH MỤC THU NHẬP (Income)
INSERT INTO coinsort.categories (name, type, icon_name, color_hex, is_default, order_index) VALUES
  ('Salary', 'income', 'payments', '#00FA9A', true, 1),
  ('Bonus', 'income', 'military_tech', '#FFD700', true, 2),
  ('Investment', 'income', 'trending_up', '#9370DB', true, 3),
  ('Freelance', 'income', 'laptop_mac', '#1E90FF', true, 4),
  ('Gifts Received', 'income', 'redeem', '#FF69B4', true, 5),
  ('Others', 'income', 'account_balance_wallet', '#A9A9A9', true, 6);