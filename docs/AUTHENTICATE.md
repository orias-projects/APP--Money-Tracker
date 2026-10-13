# Cấu hình đăng nhập Google / Facebook / X

Cú pháp mỗi bước: **Vị trí: hành động + đối tượng.** Nhãn "…" là chữ trên màn hình.
Dán giá trị bằng nút copy hoặc gõ tay — không copy từ khung chat (dính ký tự ẩn).

**Giá trị dùng chung**

| Tên                           | Giá trị                                                     |
| ------------------------------ | ------------------------------------------------------------- |
| Callback URL (Supabase)        | `https://wymlkppuhrvxqtwlrlbv.supabase.co/auth/v1/callback` |
| Trang privacy + xoá dữ liệu | `https://coinsort-money-tracker.netlify.app/privacy.html`   |
| Package Android                | `com.coinsort.app`                                          |
| Deep link app                  | `coinsort://login-callback/`                                |

## 0. SQL (chỉ khi cài project mới)

1. Supabase → SQL Editor: chạy `Assets/SQL/INSTALL_ALL.sql`.
2. Supabase → Project Settings → Data API → "Exposed schemas": thêm `coinsort`.

## 1. Supabase → Authentication

1. Sign In / Up → provider "Email": tắt "Confirm email".
2. Sign In / Up → provider "Email": tắt "Secure email change".
3. Sign In / Up → khối "User Signups": bật "Allow manual linking".
4. URL Configuration → "Redirect URLs": thêm `coinsort://login-callback/`.
5. Sign In / Up: bật Google / Facebook / Twitter, điền khoá lấy từ mục 2–4.

## 2. Google (console.cloud.google.com)

### 2.1 Project + consent screen

1. Thanh trên cùng, ô chọn project: tạo "New project" tên `Coinsort`, chọn nó.
2. Menu ☰ → "APIs & Services" → "OAuth consent screen": bấm "Get started".
3. Form: điền App name `Coinsort`, User support email, Audience = "External", Contact email; bấm "Create".
4. Trang "Branding": tải App logo (`assets/ICO/app_icon.png`), điền Privacy policy link = trang privacy.
5. Trang "Audience" → "Test users": thêm Gmail của bạn. Khi phát hành: bấm "Publish app".

### 2.1b Xác minh thương hiệu (khi Google báo "verification" sau khi Publish)

1. Thư mục `landing/` trong repo (index.html + privacy.html): kéo thả vào Netlify — mở site `coinsort-money-tracker` → tab "Deploys" → thả thư mục vào (giữ nguyên domain, KHÔNG tạo site mới).
2. search.google.com/search-console (đăng nhập cùng Google account với Cloud project): "Add property" → "URL prefix" = `https://coinsort-money-tracker.netlify.app/`.
3. Chọn phương thức "HTML tag": copy chuỗi trong `content="..."`.
4. File `landing/index.html`: dán chuỗi thay `PASTE_GOOGLE_TOKEN_HERE` → deploy lại (bước 1) → Search Console: bấm "Verify".
5. Consent screen "Branding": sửa App name = `Coinsort` (C hoa, khớp trang chủ); "Application home page" = `https://coinsort-money-tracker.netlify.app/`.
6. Mẹo né xác minh: chỉ dùng scope email/profile thì bấm "Remove" App logo ở Branding → Google không đòi verify nữa (app vẫn chạy cho mọi người).

### 2.2 OAuth client Web

1. "Credentials" → "+ Create credentials" → "OAuth client ID": chọn type "Web application", tên `Coinsort Web`.
2. Ô "Authorized redirect URIs": thêm Callback URL (bảng trên); bấm "Create".
3. Hộp thoại kết quả: copy "Client ID" và "Client secret".
4. Supabase → Sign In / Up → Google: bật, dán Client ID vào "Client IDs", secret vào "Client Secret (for OAuth)"; Save.
5. File `.env`: thêm dòng `GOOGLE_WEB_CLIENT_ID=<Client ID Web>`; build lại app.

### 2.3 OAuth client Android (đăng nhập native)

1. PowerShell: chạy `keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android` → copy dòng SHA1.
   (Máy này: `keytool` có sẵn trong PATH — JDK Scoop, không cần Android Studio.)
2. "Credentials" → "+ Create credentials" → "OAuth client ID": type "Android", package `com.coinsort.app`, dán SHA-1; bấm "Create".
3. Lặp bước 1–2 cho khoá release (`keytool -list -v -keystore <file>.jks -alias upload`) và cho SHA-1 Play App Signing (Play Console → "App integrity" → "App signing key certificate").
4. Supabase → Google → ô "Authorized Client IDs": dán các Client ID Android (phẩy ngăn cách); bật "Skip nonce check"; Save.

**Lỗi thường gặp**

| Thông báo                            | Chỗ sửa                                                                                                        |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `DEVELOPER_ERROR` / sheet tự đóng | SHA-1 hoặc package không khớp bản build (2.3)                                                                |
| "Access blocked: … verification"      | Gmail chưa nằm trong Test users (2.1-5)                                                                        |
| Supabase "Bad ID token"                | Thiếu Android client ID trong "Authorized Client IDs" (2.3-4), hoặc`.env` dán nhầm Android ID thay vì Web |

## 3. Facebook (developers.facebook.com)

### 3.1 Tạo app

1. "My Apps": bấm "Create App".
2. Wizard: điền App name `Coinsort` + email; chọn use case "Authenticate and request data from users with Facebook Login"; chọn "I don't want to connect a business portfolio yet"; bấm "Create app".

### 3.2 Trang "App settings → Basic"

1. Đầu trang: copy "App ID" và "App secret" (bấm "Show").
2. Ô "Privacy Policy URL" / "Terms of Service URL": điền trang privacy.
3. Ô "User data deletion": chọn "Data deletion instructions URL", điền trang privacy.
4. Ô "App domains": điền `coinsort-money-tracker.netlify.app` (không có `https://`).
   Nếu bị đòi platform: cuối trang bấm "+ Add platform" → "Website", Site URL = `https://coinsort-money-tracker.netlify.app/`.
5. Ô "Namespace": điền `coinsort` (trùng thì `coinsortapp`).
6. "App icon": tải `assets/ICO/app_icon.png`; "Category": chọn Finance; bấm "Save changes".

### 3.3 Whitelist callback

1. "Use cases" → dòng Facebook Login: bấm "Customize" → tab "Settings".
2. Ô "Valid OAuth Redirect URIs": thêm Callback URL (Enter thành chip); bấm "Save changes".

### 3.4 Quyền

1. Use case → tab "Permissions and features": bấm "Add" ở dòng `email`.
2. Cùng tab: bấm "Add" ở dòng `user_friends`.
3. (Test nhiều người khi còn Development) "App roles" → "Roles": thêm Testers; tester xác nhận tại developers.facebook.com/requests.
4. (Khi phát hành, cho mọi người dùng gợi ý bạn bè) Dòng `user_friends`: bấm "Request advanced access", nộp video luồng đăng nhập→Bạn bè→Gợi ý→Mời.

### 3.5 Dán vào Supabase (client ID = App ID dạng SỐ)

1. Supabase → Sign In / Up → Facebook: bật, dán App ID vào "Facebook client ID", App secret vào "Facebook secret"; Save.

### 3.6 Khi phát hành

1. App Dashboard, công tắc "App Mode": chuyển "Live".

**Lỗi thường gặp**

| Thông báo                                      | Chỗ sửa                                                                      |
| ------------------------------------------------ | ------------------------------------------------------------------------------ |
| "URL blocked"                                    | Callback chưa lưu thành chip (3.3)                                          |
| "Invalid Scopes: email / user_friends"           | Chưa bấm Add quyền (3.4)                                                    |
| "App not active" / "Sorry, something went wrong" | App Development mode + tài khoản không phải admin/tester (3.4-3)           |
| Bộ "Kiểm tra URI" báo không hợp lệ         | Chip chưa lưu hoặc lệch ký tự — dán lại bằng nút copy của Supabase |
| Đăng nhập xong không có email               | Người dùng từ chối chia sẻ email — không phải lỗi                    |

**Test nhanh:** mở trong trình duyệt đã đăng nhập Facebook:
`https://wymlkppuhrvxqtwlrlbv.supabase.co/auth/v1/authorize?provider=facebook`
→ phải thấy màn hình "coinsort đang yêu cầu…".

## 4. X (developer.x.com) — gói Free đủ dùng

### 4.1 App

1. Developer Portal: đăng ký (mô tả tiếng Anh: "Sign in with X for Coinsort, a personal finance app. Authentication only.").
2. "Projects & Apps": mở App có sẵn trong Project (hoặc "+ Add App" tên `Coinsort`).

### 4.2 User authentication + lấy khoá

1. Trang App → tab "Settings" → "User authentication settings": bấm "Set up".
2. "App permissions": chọn "Read".
3. "Request email from users": tích.
4. "Type of App": chọn "Web App, Automated App or Bot".
5. Khối "App info": điền "Callback URI" = Callback URL (bảng trên); "Website URL" / "Terms" / "Privacy" = trang privacy; bấm "Save".
6. Popup sau khi Save: copy "OAuth 2.0 Client ID" + "Client Secret" (xem lại/tạo lại sau ở tab "Keys and tokens" → khối "OAuth 2.0 Client ID and Client Secret").

### 4.3 Dán vào Supabase

1. Supabase → Sign In / Up → dòng "X / Twitter (OAuth 2.0)": bật, dán Client ID + Client Secret; Save.
2. Dòng "Twitter (Deprecated)": để Disabled.

**Lỗi thường gặp**

| Thông báo                                                         | Chỗ sửa                                                                                                 |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| "Callback URL not approved" / "Something went wrong" khi authorize  | 4.2-5 sai Callback URI hoặc chưa Save                                                                   |
| Supabase báo sai client                                            | Dán nhầm API Key (Consumer Keys, dùng cho bản Deprecated) thay vì OAuth 2.0 Client ID/Secret         |
| Modal "Edit App Details" báo "Only valid HTTP(S) urls are allowed" | App chưa có Website URL — làm 4.2 trước rồi quay lại sửa tên/icon; modal này không bắt buộc |

**Test nhanh:** terminal chạy
`curl -sI "https://{id}.supabase.co/auth/v1/authorize?provider=x" | grep -i location`
→ phải thấy `https://x.com/i/oauth2/authorize?...`.

Giới hạn: X không mở API bạn bè cho gói Free → app chỉ đăng nhập/liên kết X, không gợi ý bạn từ X.

## 5. iOS (khi làm bản iOS)

1. Google Cloud → Credentials: tạo thêm OAuth client type "iOS", Bundle ID `com.coinsort.app`.
2. `ios/Runner/Info.plist`: thêm `GIDClientID` = iOS client ID + URL scheme đảo ngược (`com.googleusercontent.apps.…`).

## 6. Kiểm tra sau khi cấu hình

1. App: đăng ký username + mật khẩu → vào thẳng app, màn Tài khoản hiện "Chưa có email".
2. Màn Tài khoản: thêm email thật → bấm link trong mail → trạng thái "Đã xác minh".
3. App: bấm "Tiếp tục với Google" → sheet chọn tài khoản hiện ngay trong app.
4. Màn Tài khoản: bấm Liên kết Facebook → quay lại thấy tên Facebook; màn Bạn bè có khối Gợi ý.
5. Terminal (xem provider nào đã bật): `curl "https://wymlkppuhrvxqtwlrlbv.supabase.co/auth/v1/settings" -H "apikey: <SUPABASE_ANON_KEY>"`.

## Play Console — Data safety

1. Khai: thu thập Tên, Email, Ảnh đại diện (từ provider đăng nhập) + ID bạn Facebook (chỉ để gợi ý mời nhóm); không chia sẻ bên thứ ba; có xoá tài khoản.
2. Privacy policy URL: điền trang privacy (bảng trên).

---

## Phụ lục — vì sao thiết kế như vậy (tham khảo)

| Vấn đề               | Thực tế                                                                                                      | Quyết định                                                                                                     |
| ----------------------- | -------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Google native           | `google_sign_in` 7.x + `signInWithIdToken`                                                                 | Đăng nhập native; liên kết dùng`linkIdentity` (trình duyệt); lỗi cấu hình tự rơi về trình duyệt |
| Facebook / X            | GoTrue không nhận id-token của X; FB Android không có Limited-Login token                                 | Cả hai đi trình duyệt qua deep link`coinsort://login-callback`                                              |
| Bạn bè                | Google không có API; X đòi gói trả phí; FB`user_friends` chỉ trả bạn cũng dùng app + cần review | Chỉ đồng bộ FB; thêm nguồn "cùng nhóm" từ dữ liệu sẵn có                                             |
| Đăng ký không email | GoTrue bắt buộc email                                                                                        | Email tổng hợp`<username>@noemail.coinsort.app`, ẩn khỏi UI                                                 |
| Đổi/thêm email       | Link xác minh gửi tới email mới                                                                            | Phải tắt "Secure email change"                                                                                  |
| Có mật khẩu chưa    | Client không đọc được                                                                                    | RPC`get_my_login_methods()`                                                                                     |
| Gỡ liên kết cuối    | GoTrue chặn (`single_identity_not_deletable`)                                                               | UI khoá nút gỡ khi là cách đăng nhập cuối                                                                |
| Liên kết thủ công   | Cần "Allow manual linking" ON                                                                                 | Map lỗi`manual_linking_disabled` thành thông điệp rõ                                                      |
