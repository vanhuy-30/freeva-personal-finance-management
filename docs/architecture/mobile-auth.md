# Mobile auth và khóa thiết bị — MOB-P1-001

Client Flutter dùng contract `/api/v1` và quyết định email/session ở
[ADR 009](adr/009-email-auth-sessions.md). Bổ sung `POST /api/v1/auth/email-step`; không thêm refresh token.

## Luồng

- Splash → auth gate → nhập email → `email-step` chọn đăng nhập hoặc đăng ký. Email đã tồn tại (kể cả legacy) vào nhập password; email mới vào tạo password + xác nhận. Lỗi mạng/response không hợp lệ giữ màn email, không đoán account state.
- Đăng ký tự gửi mã qua outbox hiện có và UI chuyển ngay sang nhập mã xác thực; chỉ có gửi lại mã tại bước này. Sau xác thực, nhập password để đăng nhập; không giữ password trong ViewModel. Backend vẫn cho login trước verify theo ADR 009, không tự đánh dấu email đã xác thực.
- “Quên mật khẩu” chỉ xuất hiện tại màn nhập password → gửi mã → nhập mã + password mới → quay lại login. Không có nút reset/verify độc lập ở màn đầu.
- Login → thiết lập PIN 6 chữ số và xác nhận → home.
- UI giữ logo/tokens Freeva, nền surface, input/CTA bo góc, back navigation, password visibility, loading/error, l10n vi/en. Google/Apple chưa hiện vì OAuth chưa triển khai; không đưa legal draft nội bộ thành điều khoản in-app.
- Mã email là 64 ký tự hex từ mail của backend; không dùng deep link chứa token. Password 12–128 ký tự, không trim. Email trim/lowercase.
- Login nhận opaque Bearer, hạn tuyệt đối và session ID. Khởi động lại luôn khóa; nếu dừng app giữa bước login và tạo PIN thì yêu cầu login lại.
- Home có list phiên, thu hồi một phiên/mọi phiên, logout và khóa ngay. Logout online phải thành công mới xóa local; lỗi mạng cho phép thử lại. `401` của request có Bearer xóa credential và yêu cầu login.
- Quên PIN xóa credential **trên thiết bị**, không giả định đã revoke server. UI nói rõ phiên server còn đến hạn hoặc được thu hồi sau khi login lại.

## Lưu trữ và giới hạn

Mỗi môi trường và API origin có key riêng trong Keychain/Android encrypted secure storage; chuyển backend không tái sử dụng session/PIN của backend khác. Record legacy không tự migrate, cần login lại một lần.

Một record versioned chứa token, expiry,
session ID, salt/hash PIN, bộ đếm sai và lựa chọn biometric. Không lưu password/PIN thô.
PBKDF2-HMAC-SHA256, 600.000 vòng, salt ngẫu nhiên 32 byte, output 32 byte; chạy isolate để
không chặn privacy cover/UI. So sánh hash không dừng sớm theo nội dung.

Bộ đếm được ghi **trước** kiểm tra PIN, không reset bằng restart/kill app. Sau 5 lần sai,
xóa credential local và yêu cầu email/password. PIN đúng reset counter; lỗi mạng kiểm tra
phiên không bị tính như PIN sai. Bộ nhớ lỗi không cho mở khóa. Cold start không truy cập
server trước PIN; thiết lập PIN và mọi lần mở khóa đều kiểm tra phiên bằng `GET /sessions`.
Vì vậy phiên bị revoke không mở được bằng PIN/biometric, nhưng mở khóa hiện cần mạng.

Biometric là lựa chọn sau khi có PIN; chỉ hiển thị khi phần cứng có enrollment và đã bật
cho credential đó. Bật cần xác thực hệ điều hành thành công. Dùng `biometricOnly`, không
fallback passcode hệ điều hành; hủy/lỗi/không hỗ trợ vẫn có PIN. PIN luôn là fallback.

## Lifecycle và quyền riêng tư

- Auth gate không dựng home khi signed out, đang tạo PIN hoặc locked. Route protected mới phải dùng gate tương tự.
- Inactive/paused/hidden khóa và che UI ngay; kết quả unlock cũ không mở lại sau khi chuyển nền. Inactive do prompt biometric chỉ che, không hủy chính prompt đó; paused vẫn vô hiệu hóa kết quả mở khóa.
- Android: `FlutterFragmentActivity`, `USE_BIOMETRIC`, `FLAG_SECURE` chặn ảnh chụp/recents, tắt backup app để credential không restore sang máy khác.
- iOS: native cover opaque khi resign active; Face ID usage description; Keychain `unlocked_this_device`, entitlement access group giới hạn theo bundle ID. iOS không chặn screenshot chủ động lúc app foreground.
- Không log request/response, password, token, email hay PIN. Lỗi hiển thị qua mã l10n; không phản chiếu payload server.
- HTTP chỉ chấp nhận HTTPS và không theo redirect để tránh chuyển credential sang host khác.

Khóa này bảo vệ UI trên thiết bị bình thường, không phải bảo đảm chống thiết bị root/jailbreak,
runtime instrumentation hoặc rollback secure storage bởi kẻ có quyền hệ điều hành.
`local_auth` xác nhận biometric của thiết bị, không ràng buộc token bằng hardware key và
không phát hiện riêng việc thay đổi tập biometric enrollment. Review trước store thuộc `SEC-P1-001`.

## Cấu hình và kiểm chứng

Xem [mobile README](../../apps/mobile/README.md#auth--mob-p1-001). Unit/widget tests kiểm tra
contract transport, validation, PIN/restart/expiry, opt-in/cancel biometric, revoke/logout,
lifecycle và kết quả unlock đến muộn. Native Face ID/fingerprint, Keychain/Keystore và
recents cần smoke test trên thiết bị thực trước phát hành.

Kết quả local: `flutter analyze` sạch, 33 tests pass; Android `:app:assembleDebug`
(JDK 17) và iOS simulator build pass. Cold launch trên iPhone 17 Pro simulator
(iOS 26) đã hiển thị login tiếng Việt, không lỗi Keychain sau khi thêm entitlement.
Chưa chạy email/SMTP end-to-end hoặc sinh trắc học thiết bị thật.

### Email-step và quyền riêng tư

Endpoint nhận email đã trim/lowercase, trả duy nhất `{nextStep: login|register}`,
`Cache-Control: no-store`. Dùng rate guard PostgreSQL hiện có: 30/IP và 5/email
mỗi operation/15 phút, `429 + Retry-After`; không trả user ID, password hash hoặc
verification state. Luồng email-first được yêu cầu **cố ý tiết lộ sự tồn tại của account**;
rate limit chỉ giảm lạm dụng, không loại bỏ enumeration. ADR 009/threat model đã cập nhật.
Discovery không cấp quyền và không thay credential; đăng ký trùng vẫn không ghi đè.
Backend phải deploy endpoint mới trước khi phát hành mobile dùng luồng này.

Bổ sung kiểm chứng: 41 backend unit tests và 13 HTTP/PostgreSQL integration tests pass,
gồm normalization, response tối thiểu/no-store, rate limit email-step và auth regression.
