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
