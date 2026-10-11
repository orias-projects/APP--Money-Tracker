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
