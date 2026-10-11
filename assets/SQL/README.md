# SQL — backend Coinsort trên Supabase (schema `coinsort`)

Toàn bộ bảng, trigger, RLS và RPC của app nằm trong schema **`coinsort`**
(không dùng `public`). Client Flutter đã cấu hình
`PostgrestClientOptions(schema: 'coinsort')` trong `lib/main.dart`.

## Cài tự động từ máy dev (nhanh nhất)

```
# token: supabase.com/dashboard/account/tokens → ghi vào file .supabase_access_token (đã gitignore)
dart run tool/supabase_apply.dart
```

Tool chạy `INSTALL_ALL.sql`, thêm `coinsort` vào Exposed schemas (qua Management
API, hoặc rơi về SQL `alter role authenticator set pgrst.db_schemas` nếu tài
khoản không có quyền endpoint đó), và kiểm tra lại số bảng/hàm/danh mục. Phần
Auth settings (bước 3 dưới) API thường từ chối → vẫn bấm tay.

## Cài tay trên project Supabase trống

1. **Supabase Dashboard → SQL Editor** → dán toàn bộ `INSTALL_ALL.sql` → **Run**.
   File này gộp sẵn đúng thứ tự: `000_schema_setup.sql` → `schema.sql` →
   `scripts.sql` → `migrations/001…008` → `seed.sql`. Chạy xong không báo lỗi
   là backend hoàn chỉnh (25 danh mục mặc định đã có).
2. **Dashboard → Project Settings → Data API → Exposed schemas** → thêm
   `coinsort` (giữ nguyên `public`, `graphql_public`) → Save.
   Thiếu bước này client nhận lỗi *"The schema must be one of the following…"*.
3. **Dashboard → Authentication**:
   - Sign In / Up → provider Email: **Confirm email = OFF**, **Secure email change = OFF**;
     khối User Signups: **Allow manual linking = ON** (đăng ký username-only + liên kết Google/Facebook/X).
   - URL Configuration → Redirect URLs: thêm `coinsort://login-callback/`.
   - Providers: bật Google / Facebook / Twitter theo `docs/SOCIAL_AUTH_SETUP.md`.
4. **Storage**: bucket `receipts` và `avatars` được tạo bởi migration 004
   (kiểm tra ở Dashboard → Storage; nếu thiếu, chạy lại phần 004).

Có thể chạy lại `INSTALL_ALL.sql` bất cứ lúc nào trên schema **trống** — nhưng
`schema.sql` bên trong **xoá toàn bộ bảng**, nên KHÔNG chạy lại trên DB đã có dữ liệu.

## Database đã có dữ liệu (cập nhật về sau)

Chỉ chạy các file migration mới theo thứ tự số, từng file một. Tất cả migration
đều idempotent (chạy lại nhiều lần không sao).

## Danh sách file

| # | File | Nội dung |
|---|------|----------|
| 0 | `000_schema_setup.sql` | Tạo schema `coinsort`, grant usage + default privileges cho anon/authenticated/service_role (tái tạo mặc định Supabase của `public`) |
| 1 | `schema.sql` | Bảng, trigger số dư, RLS. **Xoá sạch bảng cũ trong `coinsort`.** |
| 2 | `scripts.sql` | RPC nền: đăng nhập, nhóm, lời mời |
| 3 | `migrations/001_balance_integrity.sql` | `opening_balance`, đối soát, nhật ký |
| 4 | `migrations/002_group_splits.sql` | Chia tiền, quyết toán, ví nhóm, mã mời |
| 5 | `migrations/003_indexes_and_analytics.sql` | Index, RPC gộp biểu đồ, ngân sách, định kỳ |
| 6 | `migrations/004_account_deletion_and_storage.sql` | Xoá tài khoản, bucket Storage (`receipts`/`avatars`) |
| 7 | `migrations/005_security_hardening.sql` | Siết quyền RPC/RLS, vá lỗ hổng bảo mật backend |
| 8 | `migrations/006_account_deletion_fix.sql` | Xoá tài khoản an toàn (anonymise+ban, giữ giao dịch nhóm, dọn Storage) |
| 9 | `migrations/007_account_deletion_free_email.sql` | Xoá tài khoản giải phóng email (tombstone + dọn identities) |
| 10 | `migrations/008_social_auth_and_username_only.sql` | Đăng nhập mạng xã hội, đăng ký username-only, gợi ý bạn bè |
| 11 | `seed.sql` | 25 danh mục mặc định |
| — | `INSTALL_ALL.sql` | **Bundle** gộp 0→11 theo thứ tự (sinh tự động — sửa file gốc rồi sinh lại, đừng sửa tay) |
| — | `clear.sql` | Xoá DỮ LIỆU trong `coinsort` (giữ cấu trúc) — chỉ dùng khi test |
| — | `verify_balances.sql` | Đối soát số dư ví với giao dịch |

## Ghi chú kỹ thuật về schema riêng

- Mọi hàm `security definer` đặt `set search_path = coinsort, public, extensions`
  — `extensions` để gọi `uuid_generate_v4()`/`pg_trgm` (Supabase cài extension
  ở đó), `public` để không vỡ nếu extension nằm ở public.
- Trigger `on_auth_user_created` vẫn gắn trên `auth.users` và ghi vào
  `coinsort.users`; Storage policies vẫn trên `storage.objects`.
- `000` cấp quyền mặc định giống `public` để các RPC "mặt tiền" gọi được qua
  PostgREST; migration 005 revoke chọn lọc các hàm nội bộ như trước.
- Sau khi chạy `INSTALL_ALL.sql`, kiểm tra nhanh trong SQL Editor:
  `select count(*) from coinsort.categories;` → 25.
