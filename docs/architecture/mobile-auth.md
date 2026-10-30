# Mobile auth và khóa thiết bị — MOB-P1-001

Client Flutter dùng contract `/api/v1` và quyết định email/session ở
[ADR 009](adr/009-email-auth-sessions.md). Không thêm refresh token. Giao diện theo [nhóm A](../brand/patterns/A-onboarding-auth.md) (`DS-P2-004`); mobile không còn gọi `email-step` (backend vẫn giữ).

## Luồng

- Splash → auth gate → lần đầu cài là Welcome ("Bắt đầu" → Tạo tài khoản Freeva: Google/Apple "Sắp có", email; hoặc "Đăng nhập"), các lần sau là màn Đăng nhập (email + mật khẩu cùng một màn, "Quên mật khẩu?", Google/Apple, "Đăng ký"). Google/Apple hiện nút nhưng chỉ báo "Sắp có" (OAuth mobile chưa làm).
- Đăng ký email: email, mật khẩu, nhập lại, danh sách điều kiện tự tick, ô đồng ý Điều khoản và Chính sách (`/help/legal` mở được khi chưa đăng nhập). `POST /auth/register` nhận `termsAccepted: true`; backend ghi `User.termsAcceptedAt` và `termsVersion`. Backend trả 202 dù email đã có hay chưa, nên app đăng nhập ngay bằng mật khẩu vừa nhập (email trùng thất bại ở bước này với lỗi đăng nhập thông thường). Không giữ mật khẩu trong ViewModel sau bước đó.
- Sau đăng ký: stage `setup` = Xác nhận email (không bắt buộc, nút "Xong", "Gửi lại") → Mục tiêu → Thói quen → Ngân sách (mỗi câu "Để sau" được; trả lời gửi `PATCH /profile/onboarding`; số ngân sách `PUT /budgets/current` nếu chưa có, không thì giữ trên máy) → Thiết lập tài chính (mỗi loại ví một cái, tạo qua use case ví trực tiếp vì danh sách ví chỉ chạy khi đã mở khoá) → Đặt PIN → Nhập lại PIN → Face ID/vân tay (nếu máy có). Mọi bước có "Để sau". Backend cho login trước verify (ADR 009).
- "Quên mật khẩu" gửi link; sau khi gửi, màn nói "kiểm tra email". Màn Đặt mật khẩu mới có sẵn (`AuthViewModel.startReset(token)`) nhưng chưa có đường vào cho tới khi làm deep link (task riêng).
- **PIN không bắt buộc.** Không có PIN thì app không khóa khi vào nền (vẫn che màn hình) và phiên khôi phục thẳng vào app; có PIN thì khởi động lại luôn khóa. Người đã bỏ qua đặt PIN ở Cá nhân → Bảo mật → "Đặt mã PIN". Đăng nhập lại vào thẳng app, không qua bước PIN.
- UI giữ logo/tokens Freeva, nền surface, input/CTA bo góc, back navigation, password visibility, loading/error, l10n vi/en. Google/Apple chưa hiện vì OAuth chưa triển khai; không đưa legal draft nội bộ thành điều khoản in-app.
- Token trong mail vẫn là 64 ký tự hex; UI không còn ô nhập mã (chốt 2026-10-23), link mở thẳng app sẽ làm ở task riêng. Password 8–128 ký tự (`minPasswordLength`/`maxPasswordLength`, `BE-P2-014`), không trim; đăng ký và đặt lại cần thêm ít nhất một chữ và một số (`hasLetterAndDigit`, `DS-P2-004`), đăng nhập chỉ kiểm tra độ dài. Email trim/lowercase; email sai trả `invalidEmail` trước khi gọi API.
- Login nhận opaque Bearer, hạn tuyệt đối và session ID. Khởi động lại khóa nếu có PIN; chưa có PIN thì vào thẳng app.
- Home có list phiên, thu hồi một phiên/mọi phiên, logout và khóa ngay. Logout online phải thành công mới xóa local; lỗi mạng cho phép thử lại. `401` của request có Bearer xóa credential và yêu cầu login.
- Xóa tài khoản (`MOB-P2-011`): `DELETE /account` phải thành công mới xóa phiên và PIN local; lỗi mạng hoặc server từ chối thì giữ nguyên. Xuất dữ liệu lấy đúng body `GET /account/export`.
- Quên PIN xóa credential **trên thiết bị**, không giả định đã revoke server. UI nói rõ phiên server còn đến hạn hoặc được thu hồi sau khi login lại.

## Lưu trữ và giới hạn

Mỗi môi trường và API origin có key riêng trong Keychain/Android encrypted secure storage; chuyển backend không tái sử dụng session/PIN của backend khác. Record legacy không tự migrate, cần login lại một lần.

Một record versioned chứa token, expiry,
session ID, email đăng nhập, tên hiển thị (để chào ở màn Mở khoá, `DS-P2-004`), salt/hash PIN, bộ đếm sai và lựa chọn biometric. Không lưu password/PIN thô. Tên bị xoá cùng record khi đăng xuất hoặc quên thiết bị.
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

- Auth gate không dựng home khi signed out, đang thiết lập lần đầu (`setup`) hoặc locked. Route protected mới phải dùng gate tương tự.
- Inactive/paused/hidden khóa và che UI ngay; kết quả unlock cũ không mở lại sau khi chuyển nền. Inactive do prompt biometric chỉ che, không hủy chính prompt đó; paused vẫn vô hiệu hóa kết quả mở khóa.
- Android: `FlutterFragmentActivity`, `USE_BIOMETRIC`, `FLAG_SECURE` chặn ảnh chụp/recents, tắt backup app để credential không restore sang máy khác.
- iOS: native cover opaque khi resign active; Face ID usage description; Keychain `unlocked_this_device`, entitlement access group giới hạn theo bundle ID. iOS không chặn screenshot chủ động lúc app foreground.
- Không log request/response, password, token, email hay PIN. Lỗi hiển thị qua mã l10n; không phản chiếu payload server.
- HTTP chỉ chấp nhận HTTPS và không theo redirect để tránh chuyển credential sang host khác.

Khóa này bảo vệ UI trên thiết bị bình thường, không phải bảo đảm chống thiết bị root/jailbreak,
runtime instrumentation hoặc rollback secure storage bởi kẻ có quyền hệ điều hành.
`local_auth` xác nhận biometric của thiết bị, không ràng buộc token bằng hardware key và
không phát hiện riêng việc thay đổi tập biometric enrollment. `SEC-P1-001` ghi residual này trong [security-test-phase1.md](security-test-phase1.md); không gắn token vào hardware key.

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
