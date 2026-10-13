# Tạo upload keystore để ký bản release Android

> **Không** commit keystore hay `key.properties` — cả hai đã nằm trong `.gitignore`.
> Mất keystore = không thể cập nhật app trên Play Store. Sao lưu ở nơi an toàn.

## 1. Sinh keystore bằng `keytool`

`keytool` đi kèm JDK (cùng bộ với Android Studio / Flutter). Chạy lệnh sau và
điền mật khẩu khi được hỏi. Đặt file **ngoài** thư mục project để không lỡ commit.

**macOS / Linux:**

```bash
keytool -genkey -v \
  -keystore ~/coinsort-upload-keystore.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

**Windows (PowerShell):**

```powershell
keytool -genkey -v `
  -keystore "$env:USERPROFILE\coinsort-upload-keystore.jks" `
  -alias upload `
  -keyalg RSA -keysize 2048 -validity 10000
```

- `-alias upload` phải khớp `keyAlias` trong `key.properties`.
- `-validity 10000` (~27 năm) đủ dài cho vòng đời app.
- Ghi nhớ **store password** và **key password** đã nhập.

## 2. Tạo `android/key.properties`

Sao chép mẫu `android/key.properties.example` thành `android/key.properties`
rồi điền thông tin thật (dùng **đường dẫn tuyệt đối** tới file `.jks` ở bước 1):

```properties
storePassword=<mật khẩu kho vừa nhập>
keyPassword=<mật khẩu khoá vừa nhập>
keyAlias=upload
storeFile=/duong/dan/tuyet/doi/toi/coinsort-upload-keystore.jks
```

Trên Windows, `storeFile` dùng dạng `C:\\Users\\ban\\coinsort-upload-keystore.jks`
(nhân đôi dấu `\`) hoặc `C:/Users/ban/coinsort-upload-keystore.jks`.

## 3. Cách build đọc keystore

`android/app/build.gradle.kts` tự động:

- **Có** `key.properties` → build release ký bằng khoá thật (lên store được).
- **Không có** → dùng khoá debug để `flutter run --release` vẫn chạy được,
  **nhưng bản đó KHÔNG nộp store được**.

Không cần sửa Gradle — chỉ cần tạo đúng `key.properties` và file `.jks`.

## 4. Build bản release

```bash
flutter build appbundle --release   # .aab cho Google Play
flutter build apk --release         # .apk để test cài trực tiếp
```

## 5. (Khuyến nghị) Play App Signing

Khi tải `.aab` lên Play Console lần đầu, bật **Play App Signing**: Google giữ
khoá ký phát hành, keystore ở trên trở thành **upload key**. Nếu lỡ mất upload
key vẫn có thể yêu cầu Google cấp lại — an toàn hơn tự giữ khoá phát hành.
