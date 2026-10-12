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
