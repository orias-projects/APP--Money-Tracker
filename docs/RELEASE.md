# Phát hành Coinsort

## 0. Trạng thái & việc còn lại (cập nhật 01/09/2026)

### Đã xong (không cần làm lại)
- **Code**: hoàn thiện UI/UX, hiệu năng, l10n vi/en, theme sáng/tối; đăng nhập
  Google/Facebook/X; đăng ký username-only; màn Tài khoản; gợi ý bạn bè; đổi tên
  **Coinsort** (`com.coinsort.app`, deep link `coinsort://`); icon đồng xu + $.
  `flutter analyze --fatal-infos` sạch · 286 test xanh · AAB release build OK.
- **Backend** trên project Supabase `wymlkppuhrvxqtwlrlbv`: đã chạy
  `Assets/SQL/INSTALL_ALL.sql` bằng `tool/supabase_apply.dart` → 16 bảng, 48 hàm,
  31 RLS policy, 25 danh mục, bucket `avatars`/`receipts`, trigger tạo hồ sơ.
  Exposed schemas đã có `coinsort` (đặt qua SQL). REST đã kiểm chứng bằng
  publishable key: đọc danh mục 200, RPC đăng nhập 200, hàm nội bộ bị chặn 401.
  **Không chạy lại `INSTALL_ALL.sql` nữa** — `schema.sql` bên trong xoá bảng.

### Còn phải làm — theo thứ tự

**A. Supabase Dashboard — bắt buộc để app chạy được (5 phút)**
- [ ] Authentication → **Sign In / Up** (tên cũ *Providers*) → bấm provider
      **Email** → **Confirm email = OFF**
      (đăng ký username-only dùng email tổng hợp, không có hộp thư để xác nhận).
- [ ] Cùng panel Email → **Secure email change = OFF**
      (chỉ email mới nhận link khi người dùng thêm/đổi email).
- [ ] Cùng trang Sign In / Up, khối **User Signups** → **Allow manual linking = ON**
      (nút Liên kết Google/Facebook/X trong màn Tài khoản).
- [ ] Authentication → **URL Configuration** → Redirect URLs → *Add URL* → gõ tay
      `coinsort://login-callback/` (đừng copy từ khung chat — có thể kèm ký tự
      ẩn khiến dashboard báo URL không hợp lệ).
- [ ] Project Settings → Data API → Exposed schemas: xác nhận thấy `coinsort`
      (đang đặt qua SQL; nếu không thấy thì thêm tay một lần cho bền).
- [ ] Thu hồi Personal Access Token (supabase.com/dashboard/account/tokens) và
      xoá file `.supabase_access_token` trên máy.

**B. Chạy thử lần đầu (10 phút)**
- [ ] `flutter run` trên emulator → Đăng ký (username + mật khẩu) → vào được app,
      có 2 ví mặc định (Tiền mặt, Tài khoản Ngân hàng), thêm được giao dịch.
- [ ] Vào Tôi → Tài khoản: thêm email thật → nhận mail → bấm link → app mở lại,
      email hiện "Đã xác minh"; đăng xuất, đăng nhập lại bằng email đó.
- [ ] Kiểm tra phía server nếu muốn:
      `dart run tool/supabase_apply.dart --query "select count(*) from coinsort.users;"`.

**C. Đăng nhập mạng xã hội — chỉ khi muốn bật (app chạy bình thường khi chưa có)**

> **Công tắc trong app:** `SocialProvider.enabled`
> (`lib/src/features/auth/domain/social_provider.dart`) quyết định provider nào
> hiện nút. Từ 11/09/2026 **chỉ còn Google**; code của Facebook và X vẫn nguyên,
> chỉ tắt công tắc:
>
> - **Facebook** — quy trình đăng ký app + App Review quyền `user_friends` của
>   Meta quá phức tạp. Provider bên Supabase vẫn bật sẵn → thêm lại vào danh
>   sách là dùng được ngay.
> - **X** — provider bên Supabase chưa cấu hình (`/auth/v1/settings` trả
>   `twitter: false`), để nút thì người dùng bấm vào chỉ nhận lỗi. Muốn bật:
>   làm OAuth bên X Developer Portal + Supabase trước, rồi mới thêm vào danh sách.
>
> Tắt một provider nghĩa là: ẩn nút ở màn Đăng nhập/Đăng ký và màn Tài khoản,
> ẩn nút "Đồng bộ bạn Facebook" ở tab Bạn bè, và `AuthRepository` chặn thẳng mọi
> lời gọi tới provider đó (`AppErrorCode.providerDisabled`). Tài khoản đã liên
> kết từ trước vẫn hiện ở màn Tài khoản để gỡ liên kết.
> **Google đang chạy qua TRÌNH DUYỆT, không phải sheet native** — và
> `GOOGLE_WEB_CLIENT_ID` trong `.env` đang **cố ý để trống**. Đừng điền lại cho
> tới khi làm xong OAuth client Android ở gạch đầu dòng ngay dưới.
>
> Lý do (đã dựng lại bằng log trên máy thật 11/09/2026, Redmi Note 11 / Android 13):
> chưa có client Android thì Credential Manager hỏng, nhưng androidx báo lỗi đó
> **dưới dạng "người dùng huỷ"** → `google_sign_in` trả
> `GoogleSignInExceptionCode.canceled` → app hiểu là `oauthCancelled` → coi như
> người dùng tự huỷ nên **không hiện gì, không rơi về trình duyệt**. Người dùng
> bấm Google, chọn tài khoản, rồi app đứng im. Ở tầng Dart KHÔNG phân biệt được
> ca này với huỷ thật, nên cách duy nhất an toàn là tắt native cho tới khi client
> Android tồn tại.

- [ ] Google Cloud Console: OAuth client **Web** (Client ID + secret → Supabase
      Providers → Google) — **đã xong**, Supabase đang dùng client này cho luồng
      trình duyệt. Còn thiếu client **Android** (package `com.coinsort.app`,
      SHA-1 keystore release `60:A4:B3:21:02:B5:61:E7:DB:D6:83:97:5B:EB:83:1E:D5:82:5B:99`,
      cộng SHA-1 Play App Signing sau khi app lên Play, và SHA-1 debug nếu cần).
      Supabase → Google → Authorized Client IDs: thêm Android client ID, bật
      *Skip nonce check*. Làm xong mới điền lại `GOOGLE_WEB_CLIENT_ID` vào `.env`
      — và phải thử lại trên máy thật trước khi nộp store.
- [ ] ~~Meta for Developers~~ — **hoãn**. Nếu quay lại: app + Facebook Login,
      Valid OAuth Redirect URI = Callback URL của Supabase; App ID/secret →
      Supabase Providers → Facebook. Gợi ý bạn bè cần **App Review** quyền
      `user_friends` (trước đó chỉ tester thấy). Nhớ bật lại công tắc
      `SocialProvider.enabled` ở trên.
- [ ] X Developer Portal: OAuth 1.0a, bật *Request email*; API key/secret →
      Supabase Providers → Twitter. (X không có API bạn bè miễn phí — chỉ đăng nhập.)
- Chi tiết từng màn hình: [`SOCIAL_AUTH_SETUP.md`](SOCIAL_AUTH_SETUP.md).

> **Đã kiểm chứng trên máy thật (11/09/2026)**: bấm Google → Chrome mở
> `/auth/v1/authorize` → đăng nhập → Supabase trả `coinsort://login-callback/?code=…`
> → app bắt được deep link → **vào thẳng màn hình chính**. Toàn bộ chuỗi thông.

**D. Android release**
- [x] Keystore `E:/Data/Devdata/Secretkeys/coinsort-upload.jks` + `android/key.properties`
      (02/09/2026 — key.properties phải là UTF-8 KHÔNG BOM, Gradle không đọc được BOM).
- [x] `flutter build appbundle --release` → AAB 49.6MB ký `CN=Coinsort` (đã verify
      bằng `keytool -printcert -jarfile`).
- [ ] Sau khi app có trên Play Console: thêm SHA-1 keystore + SHA-1 Play App
      Signing vào Google OAuth Android client (mục C) cho đăng nhập Google native.

**E. Play Console**
- [x] **Chính sách quyền riêng tư đã lên URL công khai** (11/09/2026):
      **https://coinsort-money-tracker.netlify.app/privacy**
      (`/privacy.html` cũng ra cùng trang; landing ở
      https://coinsort-money-tracker.netlify.app/). Đã kiểm: HTTP 200, song ngữ,
      có email liên hệ `alongwokez@gmail.com` và mục hướng dẫn xoá tài khoản.
      Nguồn trong repo: `landing/privacy.html` (bản giống hệt ở `web/privacy.html`
      — **sửa thì nhớ sửa cả hai rồi deploy lại**, đừng để hai bản lệch nhau).
      Dùng chính URL này cho: Play Console (Privacy policy), Google OAuth consent,
      và Meta/X nếu sau này bật lại.
- [ ] Khai **URL yêu cầu xoá tài khoản** (Data deletion) trong Play Console →
      dùng lại đúng URL trên; trang đã mô tả sẵn luồng Cài đặt → Xoá tài khoản.
- [ ] **Data safety**: dữ liệu tài chính (giao dịch, ví), email, tên/ảnh đại diện
      và ID tài khoản từ nhà cung cấp đăng nhập; không chia sẻ bên thứ ba, không
      quảng cáo; có xoá tài khoản. (Facebook đang tắt → bản này không thu thập ID
      bạn Facebook nữa; màn Quyền riêng tư vẫn mô tả mục đó cho tài khoản đã liên
      kết từ trước — khai thêm cũng không sai, bỏ đi thì nhớ sửa cả hai chỗ.)
- [x] **Ảnh chụp màn hình điện thoại — xong (11/09/2026)**: 6 ảnh 1080×2400 ở
      `store_assets/screenshots/` (Giao dịch · Biểu đồ chi · Tổng quan thu/chi ·
      Báo cáo tài sản · Thêm giao dịch · Công cụ). Play cần tối thiểu 2, tối đa 8.
      **Cách chụp** (app bật `FLAG_SECURE` nên `screencap` trả file 0 byte): tạm
      comment khối `window.setFlags(FLAG_SECURE…)` trong
      `android/app/src/main/kotlin/com/coinsort/app/MainActivity.kt`, build
      release, cài lên máy thật, chụp bằng `adb exec-out screencap -p`, rồi
      **khôi phục lại dòng đó và build lại** — kiểm chứng bằng cách chụp lại:
      file phải ra 0 byte. Đừng nộp store bản đã tắt cờ.
- [ ] (Tuỳ chọn) Ảnh tablet — Play ưu tiên hiển thị nếu có.
- [ ] Feature graphic 1024×500: đã có `store_assets/feature_graphic.png`.
- [ ] Tăng `version` trong `pubspec.yaml` mỗi lần nộp (hiện `1.0.0+1`).
- [ ] (Tuỳ chọn) `SENTRY_DSN` vào `.env` để bật crash reporting — hiện đang tắt.

**F. Kết thúc**
- [ ] Commit toàn bộ thay đổi (working tree đang có ~235 file chưa commit).
- [ ] iOS (khi làm bản iOS): add `ios/Runner/{en,vi}.lproj/InfoPlist.strings` vào
      Xcode; `GIDClientID` + URL scheme đảo ngược cho Google; build trên macOS.

---

## 1. Chuẩn bị máy chủ (một lần)

Backend nằm trong schema **`coinsort`** trên Supabase (không dùng `public`).

**Cách nhanh** (đã dùng cho project hiện tại): tạo Personal Access Token, ghi vào
`.supabase_access_token` (gitignore), chạy `dart run tool/supabase_apply.dart`.
Tool chạy `INSTALL_ALL.sql`, expose schema, kiểm tra lại; phần Auth settings API
thường từ chối (403) nên vẫn bấm tay theo mục A ở trên.

**Cách tay**:
1. Supabase Dashboard → SQL Editor → chạy `Assets/SQL/INSTALL_ALL.sql` (gộp
   header schema + schema + scripts + migrations 001…008 + seed, đúng thứ tự).
2. Project Settings → Data API → **Exposed schemas** → thêm `coinsort`.
3. Authentication → URL Configuration → Redirect URLs: `coinsort://login-callback/`.
4. Authentication → Sign In / Up → provider Email: Confirm email OFF · Secure
   email change OFF; khối User Signups: Allow manual linking ON.
5. Storage: xác nhận có bucket `receipts` và `avatars` (migration 004 tạo).
6. `.env`: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (publishable key). Tuỳ chọn
   `SENTRY_DSN`, `GOOGLE_WEB_CLIENT_ID`.

Chi tiết và ghi chú kỹ thuật: `Assets/SQL/README.md`.

### 1b. Đăng nhập Google / Facebook / X (một lần)

Làm theo `docs/SOCIAL_AUTH_SETUP.md`: bật 3 provider trong Supabase, tạo OAuth
client Google (Web + Android với SHA-1 release và Play App Signing), điền
`GOOGLE_WEB_CLIENT_ID` vào `.env`. Thiếu bước Google native thì nút Google vẫn
chạy qua trình duyệt.

## 2. Kiểm tra trước khi build

```bash
flutter analyze --fatal-infos    # phải sạch
flutter test                     # phải xanh hết
dart format --output=none --set-exit-if-changed lib test
```

Và trong SQL Editor, chạy [`Assets/SQL/verify_balances.sql`](../Assets/SQL/verify_balances.sql).
**Kết quả phải rỗng** — có dòng nào nghĩa là số dư ví đang lệch sổ giao dịch.

## 3. Tạo khoá ký Android (một lần)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Sao chép `android/key.properties.example` thành `android/key.properties` rồi điền:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=C:/Users/orias/coinsort-upload.jks
```

> **Giữ file `.jks` và `key.properties` thật cẩn thận.** Mất khoá là không cập
> nhật được app trên Play Store nữa. Cả hai đã nằm trong `.gitignore` — đừng bao
> giờ commit chúng.

Không có `key.properties`, bản release sẽ ký bằng khoá debug: chạy được trên máy
nhưng **không lên store được**.

Lấy SHA-1 (cho Google OAuth Android client):

```bash
keytool -list -v -keystore "$env:USERPROFILE\coinsort-upload.jks" -alias upload
```

## 4. Build

```bash
flutter build appbundle --release   # AAB cho Google Play
flutter build apk --release         # APK để gửi trực tiếp
flutter build web --release         # Web → build/web
flutter build ipa --release         # iOS (cần macOS)
```

Máy build phải có file `.env` đúng — `flutter_dotenv` nhúng giá trị vào lúc build.

## 5. Checklist lên store

Danh sách đầy đủ và nhật ký từng đợt xem
[docs/PRODUCTION_READINESS.md](PRODUCTION_READINESS.md). Tóm tắt trạng thái:

**Tài sản thương hiệu & metadata**
- [x] Icon Coinsort (đồng xu + $ nét trắng trên nền vàng; adaptive + monochrome
      Android 13) và splash (kể cả Android 12+) đã sinh cho cả 3 nền tảng từ
      `tool/gen_icon.dart`.
- [ ] Ảnh chụp màn hình (điện thoại + tablet) — chụp từ **emulator** (FLAG_SECURE).
- [ ] Tăng `version` trong `pubspec.yaml` cho mỗi bản nộp.

**Quyền riêng tư & dữ liệu**
- [x] Màn Quyền riêng tư trong app đã bao gồm dữ liệu từ nhà cung cấp đăng nhập
      và ID bạn Facebook.
- [x] Đăng nội dung đó lên **URL công khai** kèm **email liên hệ thật**:
      https://coinsort-money-tracker.netlify.app/privacy
- [ ] Khai URL đó + **URL yêu cầu xoá tài khoản** trong Play Console.
- [x] Luồng xoá tài khoản (Cài đặt → Xoá tài khoản) — migration 006 + 007 đã nằm
      trong `INSTALL_ALL.sql` và đã chạy trên project hiện tại.
- [ ] Khai báo Data Safety (Play) / App Privacy (App Store) theo mục E.

## 6. Deploy web

Upload `build/web` lên host tĩnh bất kỳ:

```bash
cd build/web && vercel --prod                    # Vercel
netlify deploy --prod --dir=build/web            # Netlify
firebase deploy                                  # Firebase Hosting
```

## Xử lý sự cố

**Bấm nút đăng nhập mạng xã hội mà KHÔNG có gì xảy ra** — hai nguyên nhân đã gặp,
cả hai đều im lặng tuyệt đối:
1. Thiếu khai báo `<queries>` trong `AndroidManifest.xml`. Từ Android 11, app
   không khai thì không "nhìn thấy" trình duyệt; `url_launcher` trả `false`,
   KHÔNG bung intent, không ném lỗi. `url_launcher_android` **không** tự khai hộ.
   Manifest hiện đã có `VIEW+https`, `VIEW+http` và `CustomTabsService` — đừng xoá.
2. Google native hỏng cấu hình bị báo thành "huỷ" — xem khung ở mục C.

**"Failed host lookup"** — Kiểm tra mạng; kiểm tra project Supabase không bị
Paused (bản free tự tạm dừng khi lâu không dùng); kiểm tra `.env` trên máy build
đúng project.

**"The schema must be one of the following: public, graphql_public"** — schema
`coinsort` chưa được expose. Project Settings → Data API → Exposed schemas → thêm
`coinsort`, hoặc chạy lại `dart run tool/supabase_apply.dart --skip-sql`.

**PGRST205 "Could not find the table … in the schema cache"** — PostgREST chưa
nạp lại cấu trúc sau khi tạo bảng. Chạy
`dart run tool/supabase_apply.dart --query "notify pgrst, 'reload schema';"`.

**"Máy chủ chưa được cài đặt đầy đủ"** — Thiếu RPC. Với project đã có dữ liệu,
chỉ chạy migration còn thiếu trong `Assets/SQL/migrations` (không chạy INSTALL_ALL).

**"Bạn không có quyền thực hiện thao tác này"** — RLS chặn. Kiểm tra đã chạy
migration 002 (policy ví dùng chung) chưa.

**Đăng ký xong không vào được app / báo "kiểm tra email để xác nhận"** —
Dashboard vẫn để Confirm email = ON. Tắt theo mục A.

**Số dư ví sai** — Vào Cài đặt → Đối soát số dư. Nếu vẫn lệch, chạy
`verify_balances.sql` để xem ví nào lệch và bao nhiêu.
