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
