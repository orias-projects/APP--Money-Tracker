-- =============================================================================
-- XÓA TOÀN BỘ DỮ LIỆU TRONG coinsort (giữ nguyên cấu trúc bảng, trigger, RLS, RPC).
-- Chạy trong Supabase Dashboard → SQL Editor.
-- =============================================================================
-- Lưu ý:
-- - Không xóa auth.users (Supabase Auth). Sau khi chạy, user cũ đăng nhập lại sẽ
--   không còn row trong coinsort.users → có thể cần đăng ký lại hoặc đồng bộ từ auth.
-- - CASCADE sẽ xóa: users, groups, group_members, group_invitations, accounts,
--   categories, tags, transactions, transaction_tags, budgets, recurring_transactions, debts_loans.
-- =============================================================================

truncate table coinsort.users, coinsort.groups restart identity cascade;
