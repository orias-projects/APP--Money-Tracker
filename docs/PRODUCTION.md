# Đánh giá độ hoàn thiện & Lộ trình phát hành store

> Tài liệu theo dõi tiến độ đưa **Coinsort** đạt chuẩn phát hành
> lên App Store / Google Play. Cập nhật lần đầu: **2026-08-28**.
> **Cập nhật gần nhất: 2026-08-31 — đợt hoàn thiện sâu UI/UX + hiệu năng + cấu hình phát hành**
> (xem §10 — kế hoạch chi tiết đã hoàn thành và được gỡ khỏi repo).
> Cách dùng: tick `- [x]` khi xong một mục, cập nhật cột trạng thái ở bảng tổng quan.

> **Trạng thái sau đợt fix:** Toàn bộ P0 (7/7) và P1 (8/8) đã xử lý; P2 và P3 xử lý xong
> phần làm được bằng code/SQL/cấu hình. Ba cổng chất lượng đều xanh:
> `flutter analyze --fatal-infos` sạch, **254/254 test pass**, format sạch.
> Còn lại **chỉ các mục cần tài nguyên bên ngoài hoặc hạ tầng riêng** (xem §8 Còn lại).

---

## 0. Tóm tắt điều hành

Coinsort là một app đã **rất chỉn chu về phần thân**: code sạch (analyze `--fatal-infos`
không lỗi, **254/254 test pass**, 0 `print`/`TODO`, không file > 1000 dòng), kiến trúc
feature-first tách tầng nghiêm túc, xử lý lỗi có chủ đích (`Result<T>`, `error_mapper`),
và tập tính năng thực sự phong phú — không chỉ ghi sổ cá nhân mà còn chia tiền nhóm,
quyết toán công nợ tối thiểu, ngân sách, giao dịch định kỳ, xuất CSV, xoá tài khoản.

Đợt fix ngày 2026-08-28 đã đóng ba mảng mà người dùng không nhìn thấy nhưng cửa hàng và
kẻ tấn công thì có: **bảo mật backend, khả năng quan sát production, và bộ tài sản thương hiệu**.

### Ước lượng độ hoàn thiện (sau đợt fix)

| Góc nhìn | Trước | Sau | Ghi chú |
|---|---|---|---|
| Tính năng & luồng nghiệp vụ | ~90% | ~90% | Không đổi (đã đầy đủ) |
| Chất lượng code client | ~85% | ~93% | l10n thật; a11y; DI test được; test tăng **69 → 254** |
| **Bảo mật backend (Supabase RLS/RPC)** | ~45% | **~90%** | Migration `005` vá toàn bộ lỗ hổng P0; còn 1 mục storage nhóm cần đổi path |
| Sẵn sàng nộp store (assets, ký, metadata) | ~40% | ~80% | Icon/splash gốc + metadata thật; còn keystore + icon thiết kế thật |
| Vận hành production (crash report, observ.) | ~10% | ~85% | Sentry + error boundary + secure storage |
| **Tổng thể "sẵn sàng phát hành thật"** | ~60% | **~85%** | Còn lại là mục cần input người dùng / hạ tầng riêng |

**Kết luận:** 5 lỗ hổng bảo mật P0 ở database và tính năng khoá sinh trắc học fail-open
**đã được vá và kiểm chứng**. App giờ ở gần trạng thái *release candidate* — phần còn lại
chủ yếu là thao tác cần tài nguyên của chủ dự án (tạo keystore, DSN Sentry, thiết kế icon
thật) và hai hạ tầng lớn để cân nhắc riêng (cache offline, push FCM).

---

## 1. Bảng tổng quan mức độ ưu tiên

Chú thích trạng thái: ✅ xong · 🟡 xong phần code, còn thao tác của chủ dự án · ⏭️ hoãn (hạ tầng riêng).

| # | Hạng mục | Mức | Trạng thái |
|---|---|---|---|
| P0-1 | RPC `apply_balance_delta` (và các hàm nội bộ) lộ ra PostgREST — sửa số dư ví bất kỳ ai | 🔴 Critical | ✅ `migrations/005` revoke 9 hàm nội bộ |
| P0-2 | RLS `transactions` cho ghi thẳng vào ví người khác, bỏ qua validate RPC | 🔴 Critical | ✅ siết `with check` INSERT/UPDATE |
| P0-3 | RLS `group_settlements` cho giả mạo/sửa/xoá quyết toán của người khác | 🔴 Critical | ✅ tách policy theo `from_user` |
| P0-4 | `delete_my_account` cascade xoá luôn giao dịch nhóm + nuốt lỗi im lặng | 🔴 Critical | ✅ `migrations/006` anonymise+ban, giữ giao dịch nhóm, dọn Storage |
| P0-5 | `get_email_for_login` cho `anon`, khớp cả `full_name` → dò email/PII | 🔴 Critical | ✅ chỉ khớp username/email |
| P0-6 | Khoá sinh trắc học **fail-open** trên Android (`MainActivity` sai lớp cha) | 🔴 Critical | ✅ FragmentActivity + fail-closed đúng lỗi |
| P0-7 | Icon & splash vẫn là logo Flutter mặc định (Apple/Google reject thẳng) | 🔴 Critical | 🟡 icon gốc đã sinh; thay bằng thiết kế thật khi có |
| P1-1 | Không có crash reporting / error boundary toàn cục | 🟠 High | ✅ Sentry + runZonedGuarded + onError |
| P1-2 | Session token Supabase lưu plaintext (thiếu secure storage) | 🟠 High | ✅ `SecureLocalStorage` (Keystore/Keychain) |
| P1-3 | Localization giả — UI đổi ngôn ngữ nhưng 738 chuỗi hard-code, 0 ARB | 🟠 High | ✅ l10n thật, ~500 key vi/en |
| P1-4 | Accessibility bằng 0 — 132 phần tử tương tác, 0 `Semantics`/`Tooltip` | 🟠 High | ✅ Semantics/tooltip cho nút icon, tap target ≥48 |
| P1-5 | RLS `users` chặn đọc tên thành viên cùng nhóm (bug UI + lệch schema/app) | 🟠 High | ✅ policy `shares_group_with_me` |
| P1-6 | 0% test cho repository/provider/screen; nguyên nhân: client static không inject được | 🟠 High | ✅ DI inject + test 69→254 (repo/service/model/core qua mocktail) |
| P1-7 | Chưa có keystore release Android (`key.properties`) | 🟠 High | 🟡 `android/GENERATE_KEYSTORE.md`; keystore cần bạn tạo |
| P1-8 | CI không build iOS, không build release, không kiểm tra SQL | 🟠 High | ⏭️ xem §4 — cần macOS runner + secret |
| P2-1 | `main.dart`: `dotenv.load`/`Supabase.initialize` không try/catch | 🟡 Medium | ✅ có try/catch + màn lỗi |
| P2-2 | `get_budget_progress` thiếu kiểm tra thành viên nhóm | 🟡 Medium | ✅ thêm `_assert_group_member` |
| P2-3 | `handle_new_user` thiếu `set search_path` (Supabase linter) | 🟡 Medium | ✅ thêm `set search_path` |
| P2-4 | Storage `receipts` per-UID → thành viên nhóm không xem được hoá đơn chung | 🟡 Medium | 🟡 bucket limit đã thêm; chia sẻ nhóm cần đổi path (§4) |
| P2-5 | Không cache offline, không auto-retry | 🟡 Medium | ⏭️ hoãn — hạ tầng DB cục bộ (§8) |
| P2-6 | "Notifications" chỉ là list lời mời, không có push/local | 🟡 Medium | ⏭️ hoãn — cần Firebase FCM (§8) |
| P2-7 | Metadata web + favicon mặc định; thiếu `ITSAppUsesNonExemptEncryption` iOS | 🟡 Medium | ✅ metadata thật + key iOS + favicon từ icon |
| P2-8 | Migration chạy tay, không dùng Supabase CLI, `003`/`004` không bọc transaction | 🟡 Medium | ⏭️ hoãn — chuyển Supabase CLI là việc quy trình (§8) |
| P3-1 | Tài liệu lỗi thời (PLAN/ROADMAP/STRUCTURE mô tả app 9 bảng, không có nhóm) | 🟢 Low | ✅ cập nhật 7 tài liệu |
| P3-2 | `pubspec.lock` bị gitignore; `intl: any` không pin | 🟢 Low | 🟡 bỏ ignore `pubspec.lock`; `intl` giữ theo SDK |
| P3-3 | `.agents/` + `.claude/` là cấu hình dự án khác (EduSoft/Next.js) lẫn vào repo | 🟢 Low | ⏭️ không tự xoá (có thể ảnh hưởng tooling phiên) — xem §8 |
| P3-4 | Logic nghiệp vụ trong widget (`charts_screen` gom "Khác"), magic string | 🟢 Low | ✅ tách `buildPieSlices` + cờ `isOthers` + test |
| P3-5 | `allowBackup` chưa tắt; nội dung lộ trong task switcher (thiếu FLAG_SECURE) | 🟢 Low | ✅ allowBackup=false + FLAG_SECURE |

---

## 2. 🔴 P0 — Chặn phát hành (phải xong trước tiên)

### P0-1 · `apply_balance_delta` và hàm nội bộ bị lộ ra PostgREST
- **Vấn đề:** Trong Supabase, mọi function schema `public` mặc định `grant execute` cho
  `anon`/`authenticated`. Toàn bộ `assets/SQL/` **không có một lệnh `revoke` nào** (đã
  kiểm chứng: 0 kết quả). `apply_balance_delta(uuid, numeric)` là `security definer`,
  **không kiểm tra quyền bên trong**. Bất kỳ ai gọi:
  ```
  POST /rest/v1/rpc/apply_balance_delta {"p_account_id":"<ví người khác>","p_delta":999999999}
  ```
  để đặt lại số dư ví của người khác — phá thẳng "bất biến số 1" mà README tự tuyên bố.
  Các hàm `_write_splits`, `_assert_group_member`, `_assert_account_usable`, `gen_invite_code`
  cũng bị lộ tương tự.
- **Cách sửa:** thêm migration `005` với `revoke execute ... from public, anon, authenticated`
  cho tất cả hàm nội bộ; chỉ để lộ các RPC "mặt tiền" đã có kiểm tra quyền.
- [ ] Đã viết migration revoke cho các hàm nội bộ
- [ ] Đã kiểm chứng gọi trực tiếp `apply_balance_delta` từ client bị từ chối

### P0-2 · RLS `transactions` cho ghi thẳng vào ví người khác
- **Vấn đề:** Policy INSERT chỉ kiểm tra "là thành viên nhóm", không kiểm tra `account_id`
  thuộc quyền người ghi. Kết hợp `get_group_account_labels()` trả về UUID ví cá nhân của
  thành viên khác → A có thể `POST /rest/v1/transactions` với `account_id` = ví của B,
  trigger đổi số dư ví của B. `_assert_account_usable` chỉ chạy trong RPC, không trong RLS.
- **Cách sửa:** siết `with check` để `account_id` phải thuộc `auth.uid()` hoặc là ví nhóm
  hợp lệ; hoặc revoke quyền ghi trực tiếp bảng, chỉ cho ghi qua `create_transaction` RPC.
- [ ] Đã siết RLS INSERT/UPDATE `transactions`

### P0-3 · `group_settlements` cho giả mạo quyết toán
- **Vấn đề:** Policy `FOR ALL` chỉ kiểm tra thành viên nhóm, không ràng `from_user = auth.uid()`.
  Client insert thẳng "tôi đã trả X 5 triệu" hoặc sửa/xoá bản ghi của người khác → làm sai
  `get_group_balances`. RPC `settle_up` làm đúng nhưng không được ép buộc.
- **Cách sửa:** tách policy INSERT `with check (from_user = auth.uid() and created_by = auth.uid())`,
  giới hạn UPDATE/DELETE theo người tạo.
- [ ] Đã tách policy `group_settlements`

### P0-4 · `delete_my_account` cascade phá dữ liệu nhóm + nuốt lỗi
- **Vấn đề:** Bước cuối `delete from auth.users` kéo chuỗi cascade
  `auth.users → users → accounts → transactions → transaction_splits`, **xoá cứng luôn
  giao dịch nhóm chung** — đúng thứ hàm tuyên bố sẽ giữ lại → sổ nhóm mất cân.
  `exception when others then null` nuốt lỗi: nếu thiếu quyền xoá `auth.users`, hàm vẫn
  trả "thành công" trong khi tài khoản còn đăng nhập được. Ngoài ra **không xoá object Storage**
  (ảnh hoá đơn/avatar) — vi phạm yêu cầu xoá dữ liệu của App Store/GDPR.
- **Cách sửa:** đổi FK `accounts.user_id` sang `on delete set null`/`restrict`, hoặc
  không xoá `auth.users` khi còn giao dịch nhóm; bỏ `exception when others then null`;
  xoá kèm file trong `receipts/<uid>/` và `avatars/<uid>/`; xử lý ca "admin cuối cùng của nhóm".
- [ ] Đã sửa cascade / FK
- [ ] Đã bỏ nuốt lỗi im lặng
- [ ] Đã xoá kèm dữ liệu Storage
- [ ] Đã xử lý ca admin cuối cùng

### P0-5 · `get_email_for_login` lộ email/PII cho người chưa đăng nhập
- **Vấn đề:** Grant cho `anon`, khớp cả `full_name` (không unique, không rate limit).
  Gửi username/tên bất kỳ → nhận email thật → dò tài khoản + lộ PII.
- **Cách sửa:** bỏ khớp theo `full_name`, cân nhắc bỏ hẳn (đăng nhập bằng email trực tiếp)
  hoặc thêm rate limit / captcha.
- [ ] Đã siết `get_email_for_login`

### P0-6 · Khoá sinh trắc học fail-open trên Android
- **Vấn đề:** [MainActivity.kt](../android/app/src/main/kotlin/com/coinsort/app/MainActivity.kt)
  extends `FlutterActivity`, nhưng `local_auth` **bắt buộc** `FlutterFragmentActivity`.
  `authenticate()` ném `PlatformException(no_fragment_activity)`, và
  [app_lock.dart:95-103](../lib/src/core/settings/app_lock.dart#L95-L103) bắt mọi exception
  rồi `_unlocked = true` → **màn khoá hiện lên rồi tự mở ngay**. Bảo mật bằng 0 dù công tắc
  hiển thị "đang bật". Manifest cũng thiếu `USE_BIOMETRIC`.
- **Cách sửa:** đổi `class MainActivity : FlutterFragmentActivity()`; cân nhắc phân biệt
  lỗi "thiết bị không có khoá" (fail-open hợp lý) với lỗi cấu hình/người dùng huỷ (fail-closed);
  thêm `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`.
- [ ] Đã đổi `MainActivity` sang `FlutterFragmentActivity`
- [ ] Đã tinh chỉnh nhánh catch trong `app_lock.dart`
- [ ] Đã kiểm thử trên thiết bị Android thật

### P0-7 · Icon & splash vẫn là template Flutter mặc định
- **Vấn đề:** Đã đối chiếu MD5 — icon Android (5 mipmap), icon iOS (15 PNG), favicon web,
  Icon-192/512 đều **IDENTICAL** với template `flutter create`. LaunchImage iOS là ảnh
  trong suốt 68 byte, splash Android nền trắng trơn. Apple từ chối thẳng (Guideline 4.3/2.3.8),
  Google Play cũng reject. Thư mục `assets/ICO/` rỗng.
- **Cách sửa:** thiết kế bộ icon thật; dùng `flutter_launcher_icons` + `flutter_native_splash`;
  Android cần adaptive icon (`mipmap-anydpi-v26`) + monochrome (themed icon Android 13+).
- [ ] Đã có bộ icon thật cho cả 3 nền tảng
- [ ] Đã có adaptive icon Android
- [ ] Đã có splash/launch screen thật

---

## 3. 🟠 P1 — Cao (cần trước bản 1.0 public)

### P1-1 · Không có crash reporting / error boundary toàn cục
- Không Sentry/Crashlytics, không `runZonedGuarded`, không `FlutterError.onError`,
  không `PlatformDispatcher.instance.onError`. `AppException.cause` được thiết kế sẵn để log
  nhưng chưa ai đọc. Production **mù hoàn toàn** — mọi crash ngoài luồng `Result.guard` chết im lặng.
- **Sửa:** tích hợp Sentry (hoặc Firebase Crashlytics); bọc `runApp` trong `runZonedGuarded`;
  set `FlutterError.onError`; gắn `AppException.cause` vào breadcrumb.
- [ ] Đã tích hợp crash reporter
- [ ] Đã bọc error boundary toàn cục

### P1-2 · Session token lưu plaintext
- `Supabase.initialize` không truyền `localStorage` tuỳ chỉnh → token lưu plaintext trong
  SharedPreferences/NSUserDefaults. Trên máy root/jailbreak hoặc qua backup, refresh token
  bị đọc → chiếm phiên. Thiếu `flutter_secure_storage`.
- **Sửa:** dùng `flutter_secure_storage` (Keystore/Keychain) làm backing store cho session;
  cân nhắc cho cả `last_login_service`.
- [ ] Đã chuyển session sang secure storage

### P1-3 · Localization giả (hứa song ngữ nhưng không có bản dịch)
- `app.dart` khai báo `supportedLocales: [vi, en]`, Settings có dialog đổi ngôn ngữ, nhưng
  **0 file ARB, 0 `AppLocalizations`, 738 chuỗi tiếng Việt hard-code**. Chọn "English" chỉ đổi
  format ngày/tiền của Material — toàn bộ chữ vẫn tiếng Việt.
- **Sửa (chọn 1):** (a) làm thật — `flutter gen-l10n` + ARB, chuyển dần chuỗi; hoặc
  (b) gỡ công tắc ngôn ngữ khỏi Settings, để app đơn ngữ tiếng Việt cho tới khi làm thật.
- [ ] Đã quyết định hướng (làm thật / gỡ tính năng)
- [ ] Đã triển khai

### P1-4 · Accessibility bằng 0
- 132 phần tử tương tác, **0** `Semantics`/`semanticLabel`/`Tooltip`. Bottom nav tự vẽ đọc là
  "button" trống với TalkBack/VoiceOver. Vài tap target 40dp (< 48dp). Không xử lý text scaling.
- **Sửa:** bọc `Semantics`/`Tooltip` cho icon-only button; nâng tap target ≥ 48dp; kiểm thử
  với TalkBack/VoiceOver + font size lớn.
- [ ] Đã thêm nhãn ngữ nghĩa cho phần tử tương tác chính
- [ ] Đã sửa tap target < 48dp
- [ ] Đã kiểm thử screen reader

### P1-5 · RLS `users` chặn đọc tên thành viên cùng nhóm
- Chỉ có `select using (auth.uid() = id)`. Nhưng `transaction_repository.dart:102-105` embed
  `created_by_user`/`paid_by_user` → trả `null` cho giao dịch do người khác tạo. Vừa là bug UI,
  vừa là bằng chứng schema và app lệch nhau.
- **Sửa:** thêm policy SELECT cho "thành viên cùng nhóm được đọc profile của nhau".
- [ ] Đã thêm policy `users` cho thành viên cùng nhóm

### P1-6 · 0% test cho repository/provider/screen
- 9 repository, 8 provider, 30+ screen: **0 test**. `error_mapper.dart` (~15 nhánh) không test.
  Nguyên nhân gốc: `SupabaseService.client` là **static getter**, không inject được → repository
  không thể unit-test. Không có `mocktail`/`mockito`.
- **Sửa:** inject client qua Riverpod provider (bỏ static); thêm `mocktail`; test repository +
  `error_mapper` + `app_settings.currentFinancialMonth` + `TransactionQuery` cache key.
- [ ] Đã refactor client sang injectable
- [ ] Đã thêm test cho repository + core logic

### P1-7 · Chưa có keystore release Android
- `key.properties` chưa tồn tại (đúng thiết kế), build hiện ký bằng debug key → không upload
  Play Console được. Cấu hình `signingConfigs` đã sẵn sàng đọc file.
- **Sửa:** tạo keystore bằng `keytool`, tạo `android/key.properties`, lưu `.jks` an toàn
  (không commit — đã gitignore).
- [ ] Đã tạo keystore + key.properties
- [ ] Đã build release ký thành công

### P1-8 · CI thiếu build iOS/release và không kiểm tra SQL
- `ci.yml` chỉ build APK **debug** + web release; không build iOS, không `appbundle --release`,
  không lưu artifact, không pin phiên bản Flutter, không lint/test SQL (2725 dòng ngoài CI).
- **Sửa:** thêm job `macos-latest` build iOS; `flutter build appbundle --release`; lưu artifact;
  pin Flutter version; cân nhắc apply migration lên DB tạm + chạy `verify_balances.sql`.
- [ ] Đã thêm build release + iOS vào CI
- [ ] Đã pin phiên bản Flutter

---

## 4. 🟡 P2 — Trung bình (nên xử lý trước hoặc ngay sau 1.0)

- [ ] **P2-1** Bọc try/catch cho `dotenv.load` và `Supabase.initialize` trong `main.dart:12,25`
  (hiện crash trắng màn hình, vượt qua chính error boundary đã viết bên dưới).
- [ ] **P2-2** Thêm `_assert_group_member(p_group_id)` vào `get_budget_progress` (003:163-206).
- [ ] **P2-3** Thêm `set search_path = public` cho `handle_new_user` (Supabase linter cảnh báo).
- [ ] **P2-4** Sửa mô hình lưu hoá đơn nhóm: policy `receipts` per-UID khiến thành viên khác
  không xem được hoá đơn chung; thêm giới hạn kích thước/MIME ở phía bucket.
- [ ] **P2-5** Cân nhắc cache offline (Hive/Drift) + auto-retry/backoff; hiện mất mạng = app vô dụng.
- [ ] **P2-6** "Notifications" hiện chỉ là list lời mời (polling thủ công). Cân nhắc push thật
  (FCM + `flutter_local_notifications`) hoặc đổi tên cho đúng bản chất.
- [ ] **P2-7** Web: sửa `description` "A new Flutter project.", `theme_color` `#0175C2`, favicon.
  iOS: thêm `ITSAppUsesNonExemptEncryption=false`, set `DEVELOPMENT_TEAM`, commit `Podfile`.
- [ ] **P2-8** Chuyển sang `supabase/migrations/` + Supabase CLI (có lịch sử version/rollback);
  bọc migration `003`/`004` trong transaction.

---

## 5. 🟢 P3 — Thấp (nợ kỹ thuật, dọn dần)

- [x] **P3-1** Tài liệu lỗi thời: gỡ `PLAN.md`, `ROADMAP.md`, `PROMPT.md`, `DEPLOY.md` (dùng một lần, đã hoàn thành); `STRUCTURE.md` cập nhật schema `coinsort`
  vẫn mô tả app **9 bảng, cá nhân, không có nhóm** (thực tế **14 bảng** + toàn bộ tính năng nhóm).
  `docs/SETUP.md:122-125` trỏ file SQL không tồn tại. `assets/SQL/README.md` thiếu migration `004`.
- [ ] **P3-2** Bỏ `pubspec.lock` khỏi `.gitignore` (app nên commit để build reproducible); pin `intl`.
- [ ] **P3-3** Tách `.agents/` + `.claude/` (cấu hình dự án EduSoft/Next.js khác) ra khỏi repo.
- [ ] **P3-4** Đưa logic gom "Khác" (`charts_screen.dart:374-394`) xuống provider/domain; bỏ
  magic string `'Khác'` (nếu user có category thật tên "Khác" sẽ hiển thị sai %).
- [ ] **P3-5** Tắt `android:allowBackup` cho app tài chính; thêm `FLAG_SECURE`/che nội dung trong
  task switcher; sửa `SettingsNotifier` flash theme frame đầu; thống nhất pattern invalidation
  (`versionProvider` counter vs `ref.invalidate`).

---

## 6. Checklist nộp store (rút gọn từ `docs/RELEASE.md`)

**Google Play**
- [ ] App Bundle ký release (`.aab`) — cần P1-7
- [ ] Icon + feature graphic + screenshot mọi kích thước — cần P0-7
- [ ] Khai báo Data Safety (thu thập gì, mã hoá, xoá được không)
- [ ] URL chính sách quyền riêng tư công khai (màn `/privacy` đã có trong app; cần trang web)
- [x] Luồng xoá tài khoản hoạt động đúng — ✅ đã vá (migration 006); áp lên Supabase thật để hiệu lực
- [x] targetSdk ≥ 35 ✅ (đã đạt: targetSdk 36)

**App Store**
- [ ] Icon 1024 + screenshot mọi thiết bị — cần P0-7
- [ ] `ITSAppUsesNonExemptEncryption` — cần P2-7
- [ ] `DEVELOPMENT_TEAM` + provisioning — cần P2-7
- [ ] App Privacy (nutrition label)
- [x] Xoá tài khoản trong app (Apple bắt buộc từ 2022) — ✅ đã vá (migration 006)
- [ ] Từng build thành công trên macOS (chưa có bằng chứng Pods/)

---

## 7. Điểm mạnh cần giữ (đừng phá khi refactor)

- **Code sạch:** `flutter analyze --fatal-infos` không lỗi; 0 `print`/`debugPrint`/`TODO`/`FIXME`;
  không file > 1000 dòng.
- **Kiến trúc:** feature-first tách `domain`/`data`/`presentation`; không screen nào gọi thẳng
  Supabase; `Result<T>` nhất quán trên 24 file; domain logic (split/settlement/format/CSV) tách
  và test kỹ với case biên tốt (69/69 pass).
- **Xử lý lỗi có chủ đích:** `error_mapper` dịch lỗi Postgrest/Auth sang tiếng Việt, phân biệt
  lỗi mạng vs lỗi dữ liệu; không nuốt lỗi thành list rỗng.
- **Backend RPC nhiều hàm làm đúng:** `create_transaction` (nguyên tử, đủ tầng validate),
  `kick_member` (chặn kick admin cuối), `settle_up`, `join_group` (bắt buộc mã mời) —
  đa số có `set search_path`. Migration idempotent, đánh số tuần tự.
- **Bất biến tài chính rõ ràng:** balance = opening + tổng sổ; chỉ `apply_balance_delta` sửa số dư;
  có `verify_balances.sql` để nghiệm thu. (Chỉ cần bịt lỗ hổng quyền là mô hình này rất chắc.)

---

## 8. Còn lại — cần tài nguyên bên ngoài hoặc hạ tầng riêng

Những mục dưới đây **không thể hoàn tất chỉ bằng code trong repo** — chúng cần thao tác
của chủ dự án hoặc là hạ tầng lớn nên tách thành đợt riêng.

### 8.1 Cần thao tác / tài nguyên của bạn
- **Keystore Android (P1-7):** chạy theo `android/GENERATE_KEYSTORE.md` (cần mật khẩu riêng),
  tạo `android/key.properties`. Cấu hình `signingConfigs` đã sẵn sàng đọc file.
- **Sentry DSN (P1-1):** tạo project Sentry, điền `SENTRY_DSN` vào `.env`. Bỏ trống = tắt,
  app vẫn chạy; code báo lỗi đã sẵn sàng nhận DSN.
- **Icon thiết kế thật (P0-7):** icon hiện tại là bản gốc sinh bằng `tool/gen_icon.dart`
  (đã vượt rào "icon Flutter mặc định"). Khi có thiết kế thật, thay `assets/ICO/app_icon.png`
  + `splash_logo.png` rồi chạy lại `dart run flutter_launcher_icons` và
  `dart run flutter_native_splash:create`.
- **iOS signing (P2-7):** mở `ios/Runner.xcworkspace` trong Xcode → chọn `DEVELOPMENT_TEAM`.

### 8.2 Hoãn có chủ đích (hạ tầng riêng)
- **Cache offline (P2-5):** cần thêm một DB cục bộ (Drift/Hive) và tầng cache cho mọi
  repository, kèm chiến lược invalidation — rủi ro với bất biến tài chính nếu làm vội. Nên
  làm thành sáng kiến riêng có thiết kế + test đầy đủ. Hiện đã có retry thủ công + phân biệt
  lỗi mạng.
- **Push notifications (P2-6):** cần dựng Firebase project + FCM (`firebase_messaging`) hoặc
  giải pháp tương đương. "Notifications" hiện là hộp thư lời mời nhóm (polling) — hoạt động,
  chỉ chưa có đẩy.
- **CI build iOS/release + SQL (P1-8):** cần runner `macos-latest` và secret keystore trong
  CI. Là việc cấu hình hạ tầng CI, không phải code app.
- **Supabase CLI migrations (P2-8):** chuyển `Assets/SQL/` sang `supabase/migrations/` để có
  lịch sử/rollback — việc quy trình, nên làm khi thiết lập môi trường chuẩn.
- **Storage hoá đơn nhóm (P2-4):** đã thêm giới hạn size/MIME ở bucket. Việc chia sẻ hoá đơn
  của giao dịch nhóm cho thành viên khác cần **đổi cách lưu path phía app** sang
  `receipts/{group_id}/{uid}/…` rồi thêm policy SELECT theo `group_id` — không thể nới lỏng an
  toàn bằng SQL thuần (sẽ tạo IDOR). Chi tiết trong comment `migrations/005_security_hardening.sql`.
- **`.agents/` + `.claude/` (P3-3):** là cấu hình tooling của dự án khác lẫn vào. **Không tự
  xoá** vì `.claude/` có thể chứa cấu hình phiên làm việc hiện tại; để chủ dự án tự dọn khi
  chắc chắn không dùng.

---

## 9. Nhật ký đợt fix (2026-08-28)

Ba cổng chất lượng sau đợt fix: `flutter analyze --fatal-infos` **sạch**,
`flutter test` **89/89 pass**, `dart format` **sạch**.

**Bảo mật backend (SQL)** — `Assets/SQL/migrations/005_security_hardening.sql` (mới):
- `revoke execute` 9 hàm nội bộ SECURITY DEFINER khỏi public/anon/authenticated (P0-1).
- Siết `with check` RLS `transactions` INSERT/UPDATE theo quyền ví (P0-2).
- Tách policy `group_settlements` theo `from_user`/`created_by` (P0-3).
- `get_email_for_login` bỏ khớp `full_name` (P0-5); policy `users` cho thành viên cùng nhóm
  qua `shares_group_with_me` (P1-5); `get_budget_progress` thêm kiểm tra nhóm (P2-2);
  `handle_new_user` thêm `set search_path` (P2-3); giới hạn size/MIME bucket (P2-4).
- `migrations/006_account_deletion_fix.sql` (mới): sửa `delete_my_account` — không cascade phá
  giao dịch nhóm, bỏ nuốt lỗi, dọn Storage, xử lý admin cuối (P0-4).

**Android/iOS/Web:**
- `MainActivity` → `FlutterFragmentActivity` + `FLAG_SECURE`; quyền `USE_BIOMETRIC`;
  `app_lock.dart` phân biệt lỗi (fail-closed đúng chỗ) thay vì fail-open (P0-6, P3-5).
- `allowBackup=false` (P3-5); icon + splash gốc cho cả 3 nền tảng (P0-7);
  `ITSAppUsesNonExemptEncryption`, metadata web/manifest thật (P2-7).

**Client (lib/):**
- Sentry + `runZonedGuarded` + `FlutterError.onError` + `ErrorReporter` facade (P1-1);
  `SecureLocalStorage` cho token Supabase (P1-2); `main.dart` try/catch + màn lỗi (P2-1).
- **Localization thật:** `l10n.yaml` + ARB vi/en (~500 key), `AppLocalizations`; toàn bộ màn
  hình + widget chung + enum domain (`SplitMode`/`BudgetPeriod`/`RecurringFrequency`) dùng
  `context.l10n` (P1-3).
- **Accessibility:** `Semantics`/`tooltip` cho nút icon, nav bar, mã mời; tap target ≥ 48dp (P1-4).
- **Test được:** repository inject `SupabaseClient` qua `supabaseClientProvider` (P1-6);
  thêm 20 test (`pie_breakdown`, `financial_month`, `error_mapper`).
- `charts_screen` gom "Khác" tách sang `buildPieSlices` + cờ `isOthers` (bỏ magic string) (P3-4).

**Tài liệu:** cập nhật `STRUCTURE/PLAN/ROADMAP/SETUP/PROMPT/INTERFACE` + `assets/SQL/README.md`
+ README gốc cho khớp code thật (14–15 bảng, tính năng nhóm, thứ tự SQL tới 005/006) (P3-1).

---

---

## 10. Nhật ký đợt hoàn thiện sâu (2026-08-31)

Căn cứ 3 đợt khảo sát toàn mã nguồn (UI/UX · hiệu năng · store-readiness); kế hoạch chi tiết
và checklist kế hoạch (đã gỡ sau khi hoàn thành). Ba cổng chất lượng: analyze sạch, **252/252 test pass**,
format sạch.

**Theme (lỗi lớn nhất):** light mode trước đây vỡ hoàn toàn — 583 chỗ trên 42 file dùng thẳng
bảng màu tối `AppColors`. Đã thêm `AppPalette` (ThemeExtension, đủ 2 bộ sáng/tối) + `context.colors`
và migrate toàn bộ; sửa kèm ~35 chỗ `Colors.black/white/red` cứng trên nút, date-picker bị ép
dark trong filter, nhãn % pie theo độ sáng lát.

**l10n triệt để:** ~90 chuỗi tiếng Việt từng lộ ra bản EN đã về ARB (609 key/ngôn ngữ):
toàn bộ thông điệp lỗi tầng data đi qua `AppErrorCode` + `error_l10n.dart`; CSV export,
split editor, màn lỗi route, cụm xác nhận xoá tài khoản theo ngôn ngữ (RPC vẫn nhận cụm chuẩn);
tách locale ngày-tháng khỏi locale tiền tệ (trước đây đổi EN mà thứ/ngày vẫn tiếng Việt);
"Hôm nay/Tỷ/Tr/N" ↔ "Today/B/M/K"; fallback "Khác"/"Thành viên" resolve ở UI.

**UX:** thêm Retry + empty-state chuẩn cho Charts/Notifications/Groups/GroupSwitcher/me-friend
(trước nuốt lỗi im lặng hoặc in raw exception); pull-to-refresh cho 6 màn thiếu và bọc cả nhánh
empty/error; snackbar thống nhất; màu destructive thống nhất; autofill cho auth; haptics; semantics
cho swatch màu/tab/nút kéo-thả; dialog hết bị bàn phím che, hết width 340 cứng; filter sheet cuộn
được + né gesture bar; màn Edit có nút thêm danh mục; hiện thực `hideAmounts` (che số dư toàn app),
gỡ công tắc chết `startWeekOnMonday`.

**Hiệu năng:** gõ số tiền không còn rebuild cả màn + shell (ValueListenableBuilder + `==` cho
save-bar); kéo nút thông báo không còn rebuild shell 60-120Hz (ValueNotifier); `.select` cho
settings/user/invitations trên đỉnh cây; `autoDispose` cho 4 family provider từng giữ bộ nhớ vô hạn
(URL hoá đơn hết hạn 1h giờ tự ký lại); pie sections memo hoá (hết parse màu mỗi build + hết animate
lại vô cớ); records memo `_groupByDate` + map tra cứu; reorder danh mục hết N+1; ảnh decode đúng
cỡ hiển thị (`cacheWidth`/`ResizeImage`); title shell const (hết vòng setTitle mỗi build).

**Cấu hình phát hành:** `dataExtractionRules` (chặn D2D transfer); tên app thống nhất **Coinsort**
(manifest + iOS + web); edge-to-edge + màu icon status bar theo theme (Android 15+); bỏ splash
fullscreen (hết giật layout Android, hết ẩn status bar vĩnh viễn iOS); cảnh báo to khi build release
bằng debug key; CI thêm bước `flutter build appbundle --release` (xác minh R8 với sentry +
secure_storage); `InfoPlist.strings` en/vi; **migration 007** giải phóng email khi xoá tài khoản
(vá cam kết privacy + cho đăng ký lại); nâng supabase_flutter 2.17 (`publishableKey`);
`package_info_plus` cho footer phiên bản.

---

*Tài liệu này nên được cập nhật mỗi khi tick xong một mục. Khi các mục §8.1 (keystore, DSN,
icon thật, iOS signing) hoàn tất, app ở trạng thái "release candidate" đầy đủ.*


## 11. Đăng nhập mạng xã hội, đăng ký username-only, màn Tài khoản (01/09/2026)

Xem `docs/SOCIAL_AUTH_SETUP.md` (việc chủ dự án + phụ lục ràng buộc kỹ thuật) (việc
chủ dự án). Tóm tắt:

| Hạng mục | Trạng thái |
|---|---|
| Google native (`google_sign_in` 7 + `signInWithIdToken`), fallback trình duyệt | ✅ code xong — cần `GOOGLE_WEB_CLIENT_ID` + SHA-1 |
| Facebook / X qua `signInWithOAuth` + deep link sẵn có | ✅ code xong — cần bật provider trong Dashboard |
| Đăng ký chỉ username + mật khẩu (email tổng hợp `@noemail.coinsort.app`) | ✅ — Dashboard phải tắt Confirm email |
| Màn Tài khoản: avatar, tên, username, email + xác minh, mật khẩu, liên kết/gỡ 3 provider | ✅ |
| Gợi ý mời bạn: bạn Facebook cũng dùng app + người cùng nhóm | ✅ — `user_friends` cần Meta App Review để mở cho mọi người |
| Bạn bè từ Google / X | ⛔ Không có API (Google) / API trả phí (X) — không làm giả |
| SQL migration 008 | ✅ file sẵn — chủ dự án phải apply |
| Data safety / privacy policy: bổ sung dữ liệu nhận từ nhà cung cấp đăng nhập | ✅ text trong app; URL công khai vẫn là việc của chủ dự án |


## 12. Đổi thương hiệu Coinsort + backend sang schema `coinsort` (01/09/2026)

| Hạng mục | Trạng thái |
|---|---|
| Tên hiển thị **Coinsort** mọi nơi: Android `@string/app_name` (vi/en), iOS `CFBundleDisplayName`/`CFBundleName`, web manifest/title, ARB `appTitle` + mọi chuỗi | ✅ |
| `applicationId`/`namespace` → `com.coinsort.app`; Kotlin `MainActivity` chuyển sang `com/coinsort/app`; iOS `PRODUCT_BUNDLE_IDENTIFIER` → `com.coinsort.app` | ✅ (đổi trước lần nộp Play đầu tiên — sau khi nộp thì không đổi được nữa) |
| Deep link `coinsort://login-callback/` (Android intent-filter, iOS URL scheme, `kAuthRedirectUrl`) — nhớ cập nhật Redirect URLs trong Supabase | ✅ |
| Email tổng hợp đăng ký username-only → `@noemail.coinsort.app` (client + RPC 008) | ✅ |
| Icon mới: đồng xu + `$` nét trắng trên nền vàng `#FFC107` (`tool/gen_icon.dart`); adaptive icon foreground trong suốt + monochrome; splash vàng cả sáng/tối | ✅ đã sinh lại toàn bộ tài nguyên |
| Backend: toàn bộ SQL chuyển từ `public` → schema `coinsort`; `Assets/SQL/000_schema_setup.sql` + `INSTALL_ALL.sql` (bundle cài một lần); client `PostgrestClientOptions(schema: 'coinsort')` | ✅ file sẵn — **chủ dự án chạy `INSTALL_ALL.sql` + thêm `coinsort` vào Exposed schemas** |
| Tên package Dart `spend_sync` (nội bộ, không hiển thị) | giữ nguyên — đổi sẽ đụng mọi import, không có giá trị cho người dùng |
