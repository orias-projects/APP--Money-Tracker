-- =============================================================================
-- NGHIỆM THU GIAI ĐOẠN 0 — bất biến số dư
--
-- Chạy trong SQL Editor. KHÔNG sửa dữ liệu, chỉ đọc.
-- Kết quả RỖNG = sổ cái cân. Có dòng nào = ví đó đang lệch.
-- =============================================================================

with ledger as (
  select
    a.id,
    a.name,
    a.account_type,
    a.balance          as stored_balance,
    a.opening_balance,
    coalesce(sum(
      case
        when t.type = 'expense'  and t.account_id    = a.id then -t.amount
        when t.type = 'income'   and t.account_id    = a.id then  t.amount
        when t.type = 'transfer' and t.account_id    = a.id then -(t.amount + coalesce(t.fee_amount, 0))
        when t.type = 'transfer' and t.to_account_id = a.id then  t.amount
        else 0
      end), 0) as ledger_delta
  from coinsort.accounts a
  left join coinsort.transactions t
    on (t.account_id = a.id or t.to_account_id = a.id)
   and coalesce(t.row_status, 'active') = 'active'
  where coalesce(a.status, 'active') = 'active'
  group by a.id, a.name, a.account_type, a.balance, a.opening_balance
)
select
  id,
  name,
  account_type,
  stored_balance,
  opening_balance
    + (case when account_type = 'liability' then -1 else 1 end) * ledger_delta
    as expected_balance,
  stored_balance
    - (opening_balance
       + (case when account_type = 'liability' then -1 else 1 end) * ledger_delta)
    as drift
from ledger
where stored_balance is distinct from (
  opening_balance + (case when account_type = 'liability' then -1 else 1 end) * ledger_delta
)
order by abs(
  stored_balance - (opening_balance
    + (case when account_type = 'liability' then -1 else 1 end) * ledger_delta)
) desc;

-- -----------------------------------------------------------------------------
-- Kiểm tra phụ 1: tổng phần chia phải khớp số tiền giao dịch
-- -----------------------------------------------------------------------------
select
  t.id,
  t.amount,
  sum(s.share_amount) as split_total,
  t.amount - sum(s.share_amount) as diff
from coinsort.transactions t
join coinsort.transaction_splits s on s.transaction_id = t.id
where coalesce(t.row_status, 'active') = 'active'
group by t.id, t.amount
having abs(t.amount - sum(s.share_amount)) > 1;

-- -----------------------------------------------------------------------------
-- Kiểm tra phụ 2: tổng net của mọi thành viên trong một nhóm phải bằng 0
-- -----------------------------------------------------------------------------
select
  t.group_id,
  round(sum(paid.total) - sum(owed.total), 2) as should_be_zero
from coinsort.transactions t
cross join lateral (
  select coalesce(sum(x.amount), 0) as total
  from coinsort.transactions x
  where x.group_id = t.group_id and x.type = 'expense'
    and coalesce(x.row_status, 'active') = 'active'
    and coalesce(x.split_mode, 'none') <> 'none'
) paid
cross join lateral (
  select coalesce(sum(s.share_amount), 0) as total
  from coinsort.transaction_splits s
  join coinsort.transactions x on x.id = s.transaction_id
  where x.group_id = t.group_id and coalesce(x.row_status, 'active') = 'active'
) owed
group by t.group_id, paid.total, owed.total
having abs(paid.total - owed.total) > 1;
