# Coinsort

Ứng dụng quản lý chi tiêu **cá nhân và theo nhóm**. Ghi thu/chi/chuyển khoản,
chia tiền trong nhóm và biết chính xác ai đang nợ ai.

Flutter (Android · iOS · Web) + Supabase + Riverpod + GoRouter.

---

## Điểm khác biệt: chia tiền nhóm

Phần lớn app chi tiêu chỉ ghi sổ cá nhân. Coinsort xử lý cả câu hỏi khó hơn:
**đi ăn chung, một người trả, cuối tháng ai nợ ai bao nhiêu?**

- Mỗi khoản chi ghi rõ **ai trả** và **chia cho ai**
- Bốn cách chia: đều, số tiền cụ thể, phần trăm, theo số phần
- Màn **Công nợ nhóm** gợi ý **số lần chuyển tiền tối thiểu** để mọi người về 0
- Ví dùng chung của nhóm, hoặc ví cá nhân — cả hai đều dùng được trong nhóm

## Tính năng

| Nhóm | Có gì |
|------|-------|
| Ghi chép | Thu, chi, chuyển khoản; ảnh hoá đơn; nơi chi; ghi chú |
| Ví | Tài sản và nợ/thẻ tín dụng; ví chung của nhóm; đa tiền tệ; hạn mức thẻ |
| Nhóm | Mã mời 8 ký tự; mời theo tên; phân quyền admin; chia tiền; quyết toán |
| Phân tích | Biểu đồ donut theo danh mục, tab Tuần/Tháng/Năm, top giao dịch |
| Ngân sách | Hạn mức theo danh mục và chu kỳ, cảnh báo khi sắp vượt |
| Định kỳ | Tiền nhà, lương, gói đăng ký — tự sinh giao dịch khi tới hạn |
| Tìm kiếm | Theo từ khoá, danh mục, loại, khoảng tiền, khoảng ngày |
| Dữ liệu | Xuất CSV; đối soát số dư; tự xoá tài khoản |
| Cài đặt | 10 đơn vị tiền tệ, giao diện sáng/tối, ngày bắt đầu kỳ tài chính |

## Cài đặt

**Yêu cầu:** Flutter SDK ≥ 3.11, tài khoản Supabase, JDK 17+ (cho Android).

```bash
git clone <repo> && cd APP--Money-Tracker
flutter pub get
cp .env.example .env      # điền SUPABASE_URL và SUPABASE_ANON_KEY
```

Chạy SQL theo thứ tự trong [assets/SQL/README.md](assets/SQL/README.md):

```
INSTALL_ALL.sql (đã gộp: 000 schema `coinsort` → schema.sql → scripts.sql → migrations/001…008 → seed.sql), rồi Project Settings → Data API → Exposed schemas → thêm `coinsort`
```

> **Database đang có dữ liệu?** Đừng chạy `schema.sql` — file đó xoá bảng.
> Chỉ chạy các file trong `migrations/`. Xem README ở thư mục đó.

```bash
flutter run
```

## Kiến trúc

Feature-first, mỗi tính năng tự chứa `domain` / `data` / `presentation`.

```
lib/src/
├── core/
│   ├── constants/   AppColors, AppTheme (sáng + tối)
│   ├── errors/      AppException, error_mapper — dịch lỗi Postgrest sang tiếng Việt
│   ├── routing/     GoRouter, theo dõi trạng thái đăng nhập
│   ├── services/    Supabase client, Storage
│   ├── settings/    Cài đặt người dùng (SharedPreferences)
│   ├── utils/       Định dạng tiền tệ/ngày (intl), bảng icon danh mục
│   └── result.dart  Result<T> cho các thao tác GHI
├── common_widgets/
├── features/
│   ├── accounts/ auth/ budgets/ categories/ charts/ groups/
│   ├── recurring/ records/ reports/ search/ settings/ transactions/
└── shell/
```

**Quy ước xử lý lỗi.** Đường ĐỌC để exception bay lên, Riverpod bắt và màn hình
hiển thị qua `AsyncErrorView`. Đường GHI trả `Result<T>` để nơi gọi hiện SnackBar
với lý do thật. Không nơi nào được nuốt lỗi thành danh sách rỗng.

## Bất biến dữ liệu

Đây là app tài chính, nên có ba quy tắc không được phá:

1. **`balance == opening_balance + tổng sổ giao dịch`** với mọi ví.
   Chỉ hàm `apply_balance_delta()` trong Postgres được sửa `accounts.balance`.
   App không bao giờ `UPDATE accounts SET balance = ...` — muốn đổi số dư thì
   ghi một **giao dịch điều chỉnh**.

2. **Ví `liability` lưu số tiền đang NỢ, luôn dương.**
   Tài sản ròng = tổng `asset` − tổng `liability`.

3. **Tổng phần chia = đúng số tiền giao dịch** (cho phép lệch tối đa 1 đơn vị
   do làm tròn). RPC từ chối ghi nếu lệch hơn.

Kiểm tra cả ba bằng [`assets/SQL/verify_balances.sql`](assets/SQL/verify_balances.sql).
Kết quả rỗng = sổ cái cân.

## Phát triển

```bash
flutter analyze --fatal-infos                            # phân tích tĩnh
flutter test                                             # 69 test
dart format --output=none --set-exit-if-changed lib test # kiểm tra định dạng
```

CI chạy cả ba trên mỗi PR, cộng build Android và Web — xem
[.github/workflows/ci.yml](.github/workflows/ci.yml).

## Phát hành

Xem [docs/RELEASE.md](docs/RELEASE.md) — tạo keystore, checklist store,
cấu hình Supabase.

## Tài liệu khác

- [docs/RELEASE.md](docs/RELEASE.md) — quy trình phát hành
- [assets/SQL/README.md](assets/SQL/README.md) — thứ tự chạy SQL và quy ước dữ liệu
- [docs/STRUCTURE.md](docs/STRUCTURE.md) — sơ đồ database
- [docs/INTERFACE.md](docs/INTERFACE.md) — quy ước giao diện

## License

MIT License — see `LICENSE`.


## Repository workflow
- `orias` — feature development branch
- `dev` — integration branch for medium-sized features
- `main` — stable releases for large features
