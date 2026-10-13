# Điền Play Console — bảng đáp án cho Coinsort

> Mục đích: gỡ mọi thứ đang khoá nút gửi duyệt. Thiếu **một** mục trong
> *App content* hoặc *Store listing* là Play không cho tạo release.
> Soạn ngày 11/09/2026, dựa trên mã nguồn và cấu hình thực tế của bản hiện tại.
>
> **12 tester KHÔNG chặn việc vào review.** Yêu cầu 12 người × 14 ngày chỉ áp
> dụng khi *xin quyền phát hành công khai* (production access) với tài khoản cá
> nhân mở sau 13/11/2023. Upload AAB lên track **Closed testing** và gửi duyệt
> được ngay, kể cả khi mới có vài tester.

---

## 0. Tệp cần upload

| | |
|---|---|
| AAB | `build/app/outputs/bundle/release/app-release.aab` |
| Ký bằng | Keystore thật, `CN=Coinsort, O=Coinsort, C=VN` |
| SHA-1 | `60:A4:B3:21:02:B5:61:E7:DB:D6:83:97:5B:EB:83:1E:D5:82:5B:99` |
| Package | `com.coinsort.app` · versionName `1.0.0` · versionCode **`2`** |

> **versionCode `1` đã cháy** — dùng cho bản tải lên kênh Thử nghiệm nội bộ
> (11/09/2026, 8:22). Play không cho dùng lại mã phiên bản trên BẤT KỲ kênh nào,
> kể cả sau khi xoá bản phát hành. Mỗi lần nộp gói mới phải tăng số sau dấu `+`
> trong `pubspec.yaml`; `versionName` (`1.0.0`) thì được giữ nguyên vì đó mới là
> phiên bản người dùng nhìn thấy.
| targetSdk | 36 · minSdk 24 · hỗ trợ trang 16 KB ✅ |

Mỗi lần nộp bản mới phải tăng `version` trong `pubspec.yaml` (Play từ chối
versionCode trùng).

---

## 1. App content — Chính sách quyền riêng tư

- **Privacy policy URL**: `https://coinsort-money-tracker.netlify.app/privacy`

## 2. App content — Ads

- **Có quảng cáo trong app không?** → **Không**. App không tích hợp SDK quảng
  cáo nào (kiểm bằng `pubspec.yaml`).

## 3. App content — App access

Reviewer cần đăng nhập mới xem được gì. Chọn **"All or some functionality is
restricted"** rồi khai một mục:

| Trường | Giá trị |
|---|---|
| Tên hướng dẫn | Đăng nhập bằng tài khoản thử nghiệm |
| Username | `longtest171` |
| Password | `longtest171` |
| Hướng dẫn | Mở app → màn Đăng nhập → nhập tên đăng nhập và mật khẩu ở trên → Đăng nhập. Không cần email, không cần OTP. Tài khoản có sẵn dữ liệu mẫu (7 giao dịch, 2 ví). |

> Nút "Tiếp tục với Google" cũng hoạt động nhưng reviewer không dùng được tài
> khoản Google của bạn — cứ để họ đăng nhập bằng tên đăng nhập.

## 4. App content — Content rating

Điền bảng câu hỏi, chọn **Utility / Productivity / Communication** rồi trả lời
**Không** cho toàn bộ: bạo lực, tình dục, ngôn từ thô tục, ma tuý, cờ bạc,
nội dung người dùng tạo được chia sẻ công khai, chia sẻ vị trí, mua hàng
trong ứng dụng.

Kết quả dự kiến: **3+ / Everyone**.

## 5. App content — Target audience

- **Nhóm tuổi**: chọn **18 trở lên**. App quản lý tiền cá nhân, không nhắm trẻ
  em; chọn nhóm dưới 13 sẽ kéo theo Families Policy và bộ yêu cầu nặng hơn.
- **App có thu hút trẻ em không?** → **Không**. Giao diện, biểu tượng và nội
  dung đều hướng người lớn.

## 6. App content — Financial features

Chọn **"My app doesn't have any financial features"**.

Coinsort chỉ ghi chép chi tiêu do người dùng tự nhập. Không cho vay, không môi
giới đầu tư, không ví điện tử, không tiền mã hoá, không kết nối ngân hàng,
không xử lý thanh toán.

## 7. App content — Data safety

Đây là phần dài nhất. Trả lời chung trước:

| Câu hỏi | Đáp án |
|---|---|
| App có thu thập hoặc chia sẻ dữ liệu người dùng? | **Có — thu thập**, **không chia sẻ** với bên thứ ba |
| Dữ liệu được mã hoá khi truyền? | **Có** (toàn bộ đi qua HTTPS tới Supabase) |
| Người dùng yêu cầu xoá dữ liệu được không? | **Có** — trong app: Tôi → Cài đặt → Xoá tài khoản. URL: `https://coinsort-money-tracker.netlify.app/privacy` |
| Có tuân thủ Families Policy? | Không áp dụng (nhắm 18+) |

Các loại dữ liệu cần khai — **tất cả đều là "Collected", KHÔNG "Shared"**:

| Loại | Mục đích | Bắt buộc? |
|---|---|---|
| **Personal info → Name** | App functionality | Tuỳ chọn (tên hiển thị, hoặc lấy từ Google khi đăng nhập Google) |
| **Personal info → Email address** | App functionality, Account management | Tuỳ chọn (đăng ký chỉ cần tên đăng nhập; email thêm sau nếu muốn khôi phục mật khẩu) |
| **Personal info → User IDs** | App functionality, Account management | Bắt buộc (tên đăng nhập; ID tài khoản Google nếu đăng nhập bằng Google) |
| **Financial info → Other financial info** | App functionality | Bắt buộc — giao dịch, số dư ví, ngân sách, phần chia trong nhóm. **Đây là dữ liệu do người dùng tự nhập, không phải dữ liệu ngân hàng.** |
| **Photos and videos → Photos** | App functionality | Tuỳ chọn — ảnh hoá đơn đính kèm giao dịch; ảnh đại diện |

**KHÔNG khai** (app không dùng): vị trí, danh bạ, lịch, tin nhắn, lịch sử duyệt
web, âm thanh, tệp, hoạt động trong app, hiệu năng ứng dụng, thông tin thiết bị,
lịch sử tìm kiếm, thông tin sức khoẻ, thanh toán.

> **Nếu sau này bật `SENTRY_DSN`**: phải khai thêm **App info and performance →
> Crash logs**, và đánh dấu **Shared** với bên thứ ba (Sentry). Hiện DSN đang
> trống nên không khai.
>
> **Facebook đang tắt** nên bản này không còn thu ID bạn Facebook. Trang privacy
> vẫn mô tả mục đó cho tài khoản đã liên kết trước đây — khai dư không sai,
> nhưng nếu muốn gọn thì dọn cả trang web lẫn màn Quyền riêng tư trong app.

## 8. App content — các khai báo còn lại

| Mục | Đáp án |
|---|---|
| Government apps | Không |
| News apps | Không |
| COVID-19 contact tracing | Không |
| Data deletion | **Có** — URL ở mục 7 |
| Health apps | Không |

---

## 9. Store listing

**Tên app (30 ký tự)**

```
Coinsort – Quản lý chi tiêu
```

**Mô tả ngắn (80 ký tự)**

```
Ghi chi tiêu, chia tiền nhóm, xem biểu đồ. Gọn, riêng tư, không quảng cáo.
```

**Mô tả đầy đủ (tối đa 4000 ký tự)**

```
Coinsort giúp bạn biết tiền đi đâu — nhanh, gọn, không quảng cáo.

GHI CHÉP TRONG VÀI GIÂY
• Thêm khoản thu, chi hay chuyển khoản chỉ với vài chạm
• 25 danh mục dựng sẵn, tự thêm danh mục riêng tuỳ ý
• Để trống danh mục cũng được — phân loại sau cũng không muộn
• Đính kèm ảnh hoá đơn cho khoản cần nhớ
• Nhiều ví: tiền mặt, ngân hàng, hay bất kỳ ví nào bạn tạo

CHIA TIỀN NHÓM KHÔNG CÃI NHAU
• Tạo nhóm cho chuyến đi, bữa ăn chung hay tiền nhà
• Ghi ai trả, chia cho ai, chia đều hay theo số cụ thể
• Tự tính ai nợ ai bao nhiêu, gợi ý cách trả ít bước nhất
• Quyết toán xong là sổ sạch

NHÌN RA BỨC TRANH LỚN
• Biểu đồ thu chi theo danh mục, theo khoảng thời gian
• Báo cáo tài sản ròng, số dư từng ví
• Ngân sách theo danh mục, cảnh báo khi sắp vượt
• Giao dịch định kỳ cho tiền nhà, lương, gói đăng ký

RIÊNG TƯ
• Khoá app bằng vân tay hoặc Face ID
• Ẩn số tiền khi dùng nơi đông người
• Chặn chụp màn hình, ẩn nội dung trong danh sách app gần đây
• Không quảng cáo, không bán dữ liệu cho ai
• Xoá tài khoản và toàn bộ dữ liệu ngay trong app

TIỆN THÊM
• Tiếng Việt và tiếng Anh
• Giao diện sáng / tối
• Xuất toàn bộ giao dịch ra CSV, mở bằng Excel hay Google Sheets
• Đồng bộ nhiều thiết bị qua tài khoản
```

**Đồ hoạ**

| | Tệp |
|---|---|
| Biểu tượng 512×512 | `store_assets/icon_512.png` |
| Feature graphic 1024×500 | `store_assets/feature_graphic.png` |
| Ảnh điện thoại (8 ảnh, **1350×2400**) | `store_assets/screenshots/` |

> **Vì sao 1350×2400 chứ không phải 1080×2400:** Play bắt buộc ảnh chụp điện
> thoại có tỉ lệ **16:9 hoặc 9:16**. Máy Android hiện đại là 20:9 nên ảnh chụp
> thẳng ra (1080×2400) bị từ chối. Cắt thì mất thanh điều hướng, thu nhỏ thì mờ
> chữ — nên `tool/pad_screenshots.py` giữ nguyên từng điểm ảnh và đệm hai bên
> bằng đúng màu nền app (#121212), ra khung 1350×2400 = 16/9 chuẩn xác. Cả hai
> cạnh vẫn ≥ 1080 nên đủ điều kiện được Google giới thiệu nổi bật.
>
> Ảnh chụp gốc từ máy nằm ở `store_assets/screenshots_raw/`. Chụp lại lần sau thì
> bỏ vào đó rồi chạy `python tool/pad_screenshots.py`.

**Phân loại**

- Category: **Finance**
- Tags: quản lý chi tiêu, ngân sách, chia tiền nhóm
- Email liên hệ: `alongwokez@gmail.com`
- Website: `https://coinsort-money-tracker.netlify.app/`

---

## 10. Thứ tự làm

1. Tạo app trong Play Console (tên, ngôn ngữ mặc định **Tiếng Việt**, miễn phí)
2. Điền hết **App content** theo mục 1–8 ở trên
3. Điền **Store listing** theo mục 9
4. **Testing → Closed testing** → tạo track → upload AAB → điền release notes
5. Thêm tester (email) — thêm dần cũng được, không chặn review
6. **Gửi duyệt.** Trạng thái chuyển sang *In review*
7. Khi đủ 12 tester opt-in liên tục 14 ngày → xin **production access**

---

## 11. Ghi chú phát hành (release notes)

Play bắt buộc điền cho **ngôn ngữ mặc định**; các ngôn ngữ khác chỉ cần nếu đã
bật listing cho chúng. Giới hạn **500 ký tự mỗi ngôn ngữ** — hai bản dưới đây
lần lượt 407 và 402 ký tự.

**vi-VN**

```
Bản đầu tiên của Coinsort.

• Ghi thu, chi, chuyển khoản trong vài chạm
• Nhiều ví: tiền mặt, ngân hàng hay ví bạn tự tạo
• Chia tiền nhóm, tự tính ai nợ ai bao nhiêu
• Biểu đồ chi tiêu, báo cáo tài sản, ngân sách theo danh mục
• Giao dịch định kỳ cho khoản lặp hằng tháng
• Khoá app bằng vân tay, ẩn số tiền khi ở nơi đông người
• Xuất toàn bộ giao dịch ra CSV
• Tiếng Việt và tiếng Anh, giao diện sáng/tối
```

**en-US**

```
First release of Coinsort.

• Log income, expenses and transfers in a few taps
• Multiple wallets: cash, bank, or your own
• Split group bills and see who owes whom
• Spending charts, net worth report, budgets by category
• Recurring transactions for monthly bills
• Lock the app with your fingerprint, hide amounts in public
• Export every transaction to CSV
• Vietnamese and English, light/dark theme
```

> Bản phát hành sau: đừng bê nguyên khối này. Ghi đúng thứ đã đổi, người dùng
> đọc mục "Có gì mới" để biết bản mới khác bản cũ chỗ nào.
