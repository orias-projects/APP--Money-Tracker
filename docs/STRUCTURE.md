*Định nghĩa sơ đồ Database 16 bảng và kiến trúc thư mục Feature-first.*

# Kiến Trúc Hệ Thống (Architecture & Database)

## 1. Cơ sở dữ liệu (Supabase PostgreSQL - 16 Tables, schema `coinsort`)

Hệ thống dùng schema **`coinsort`** trên Supabase (không dùng `public`; client đặt `PostgrestClientOptions(schema: 'coinsort')`). App vừa ghi sổ **cá nhân** vừa **chia tiền theo
nhóm**, nên mọi giao dịch đều thuộc về một nhóm — khi đăng ký, mỗi người được
tạo sẵn một nhóm cá nhân ("Chi tiêu cá nhân", `is_personal = true`). Danh sách
đầy đủ theo `assets/SQL/schema.sql`:

### Người dùng & nhóm
1. **`users`**: `id` (PK, ref `auth.users`), `username`, `full_name`, `avatar_url`, `role` ('admin'/'user'), `is_premium`, `status` ('active'/'deleted').
2. **`groups`**: `id` (PK), `name`, `is_personal` (nhóm cá nhân tự tạo khi đăng ký), `invite_code` (mã mời 8 ký tự, unique), `status`.
3. **`group_members`**: `id` (PK), `group_id` (FK), `user_id` (FK), `role` ('admin'/'member'), `status` ('active'/'left'/'deleted'). Unique `(group_id, user_id)`.
4. **`group_invitations`**: `id` (PK), `group_id`, `user_id`, `invited_by`, `status` ('pending'/'accepted'/'declined').

### Ví & danh mục
5. **`accounts`**: `id` (PK), `user_id` (FK), `group_id` (FK — **null = ví cá nhân**, có giá trị = ví dùng chung của nhóm), `name`, `account_type` ('asset'/'liability'), `balance`, `opening_balance`, `credit_limit`, `currency`, `include_in_total`. Số dư chỉ đổi qua trigger `apply_balance_delta()`.
6. **`categories`**: `id` (PK), `user_id` (**null = danh mục mặc định**), `parent_id`, `name`, `type` ('income'/'expense'), `icon_name`, `color_hex` (bắt buộc cho UI), `order_index`, `is_active`.

### Giao dịch & chia tiền
7. **`transactions`**: `id` (PK), **`group_id`** (FK, **bắt buộc** — giao dịch luôn thuộc một nhóm), `account_id` (ví nguồn), `to_account_id` (ví đích — dùng cho Transfer), `category_id`, `type` ('income'/'expense'/'transfer'), `amount`, `fee_amount`, `transaction_date`, `note`, `image_url`, `payee`, `split_mode` ('none'/'equal'/'exact'/'percent'/'shares'), **`created_by`** (người tạo), **`paid_by`** (người trả), `row_status`. Trigger tự cập nhật số dư ví.
8. **`transaction_splits`**: ai gánh bao nhiêu trong một khoản chi. PK `(transaction_id, user_id)`, `share_amount`.
9. **`group_settlements`**: ghi nhận trả nợ giữa các thành viên (`group_id`, `from_user`, `to_user`, `amount`, `settled_at`, `created_by`, `row_status`).

### Nhãn, ngân sách, định kỳ, công nợ
10. **`tags`**: nhãn dán tùy chỉnh (`user_id`, `name`, `color_hex`).
11. **`transaction_tags`**: bảng nối n-n giữa `transactions` và `tags`. PK `(transaction_id, tag_id)`.
12. **`budgets`**: ngân sách chi tiêu theo danh mục (`category_id`, `amount`, `period` 'weekly'/'monthly'/'yearly'/'custom', `start_date`, `end_date`).
13. **`recurring_transactions`**: giao dịch định kỳ (`account_id`, `category_id`, `type`, `amount`, `frequency` 'daily'/'weekly'/'monthly'/'yearly', `next_date`, `is_active`).
14. **`debts_loans`**: sổ nợ/cho vay (`person_name`, `type` 'debt'/'loan', `amount`, `remaining_amount`, `due_date`).

### Nhật ký
15. **`transaction_audit`**: nhật ký ai sửa gì trên `transactions` (`action` 'insert'/'update'/'delete', `changed_by`, `old_row`/`new_row` dạng `jsonb`). Trigger tự ghi mỗi lần thêm/sửa/xoá.

### Mạng xã hội
16. **`social_friends`**: bạn bè đồng bộ từ nhà cung cấp đăng nhập (`user_id`, `provider` 'facebook'/'twitter'/'google', `friend_provider_id`, `friend_name`). PK `(user_id, provider, friend_provider_id)`, RLS chỉ chủ sở hữu. RPC `get_friend_suggestions()` khớp với `auth.identities.provider_id` để gợi ý người mời vào nhóm (kèm nguồn "cùng nhóm"). Dọn tự động khi `users.status → 'deleted'`.

> **Lưu ý:** `transactions` **không còn cột `user_id`** như bản thiết kế cũ. Quyền
> sở hữu và ngữ cảnh chia tiền được biểu diễn bằng `group_id` + `created_by` +
> `paid_by`. Toàn bộ RLS đều xoay quanh tư cách thành viên nhóm (`group_members`).

## 2. Cấu trúc Thư mục Flutter (Feature-First)

Dự án chia theo tính năng, mỗi feature tự chứa `domain` / `data` / `presentation`:

```text
lib/
├── main.dart               # Entry point
└── src/
    ├── app.dart            # Root MaterialApp (theme sáng + tối)
    ├── core/               # Thành phần dùng chung toàn app
    │   ├── constants/      # AppPalette (context.colors), AppTheme (sáng + tối)
    │   ├── errors/         # AppException, error_mapper (dịch lỗi Postgrest sang tiếng Việt)
    │   ├── routing/        # GoRouter, theo dõi trạng thái đăng nhập
    │   ├── services/       # Supabase client, Storage
    │   ├── settings/       # Cài đặt người dùng (SharedPreferences), khoá ứng dụng (app_lock)
    │   ├── utils/          # Định dạng tiền tệ/ngày (intl), bảng icon danh mục
    │   └── result.dart     # Result<T> cho các thao tác GHI
    ├── common_widgets/     # UI dùng chung (BottomNav, TransactionTile, CategoryGridItem, TabBar)
    ├── features/           # Các tính năng chính
    │   ├── auth/           # Đăng nhập, đăng ký, quên/đặt lại mật khẩu, mã khôi phục
    │   ├── accounts/       # Quản lý ví/thẻ, số dư
    │   ├── categories/     # Danh mục, icon, màu sắc
    │   ├── transactions/   # Thêm/sửa giao dịch, chia tiền (split_editor), ảnh hoá đơn
    │   ├── records/        # Trang chủ: danh sách giao dịch nhóm theo ngày
    │   ├── charts/         # Biểu đồ phân tích (donut)
    │   ├── reports/        # Báo cáo / Net Worth
    │   ├── groups/         # Nhóm, thành viên, quyết toán công nợ (settle up)
    │   ├── budgets/        # Ngân sách theo danh mục
    │   ├── recurring/      # Giao dịch định kỳ
    │   ├── search/         # Tìm kiếm & lọc giao dịch
    │   ├── notifications/  # Danh sách lời mời nhóm
    │   ├── settings/       # Cài đặt, xuất CSV, xoá tài khoản, quyền riêng tư
    │   ├── profile/        # Trang cá nhân (Me), bạn bè
    │   └── shared/         # Provider/widget dùng chung giữa các feature (filter, async states)
    └── shell/              # Khung điều hướng chính (bottom nav + app bar)
```
