# ADR 010 — Google / Apple OAuth (BE-P1-003)

- Status: accepted
- Date: 2026-09-24

## Quyết định

Backend hỗ trợ native OpenID Connect ID-token exchange; không nhận access token, không redirect/callback URL từ request. Client khởi tạo challenge trước provider sign-in. Server trả secret ngẫu nhiên 256 bit và nonce SHA-256; chỉ lưu hash, provider và expiry 5 phút. Client dùng đúng nonce server trả trong yêu cầu provider. SDK tự hash nonce phải nhận raw `challengeToken`, tránh hash hai lần. Challenge tạo bằng POST, rate limit PostgreSQL 30/IP/operation/15 phút, HTTP 429 có Retry-After. Không tin IP forwarded mặc định.

JOSE xác minh RS256, chữ ký từ JWKS HTTPS cố định theo provider (cache, cooldown, timeout 5 giây), issuer, audience allowlist từ env, authorized party nếu có, sub, iat, exp và nonce. Token tối đa 10 phút tuổi, không nhận iat tương lai. Không cấu hình client ID thì provider bị vô hiệu hóa. Lỗi token trả generic 401; provider/network/storage lỗi trả generic 503. Không log JWT, nonce, email, subject hay lỗi provider thô. Client phải giữ challenge trong đúng login attempt; dùng state/PKCE theo SDK nếu chọn authorization-code flow ngoài scope này.

Identity là `(provider, subject)` unique, không dùng email để nhận diện lần đăng nhập tiếp theo. Account mới cần email hợp lệ được provider xác thực; hỗ trợ Apple private relay và `email_verified` boolean/string. Email trùng account bất kỳ bị từ chối generic 401, không tự merge, không thay password hay emailVerifiedAt của user cũ. Không lưu name/avatar/provider access hoặc refresh token. Explicit account linking cần chứng minh cả hai identity và là scope riêng.

Consume challenge, tạo user/identity/session và audit nằm trong một transaction. Concurrent first login retry khi unique collision; replay chỉ có một lần thành công. Session creation khóa User giống password reset/revoke. Audit failure rollback cả challenge lẫn identity/session; retry chỉ được khi challenge vẫn còn hạn. Cleanup worker xóa challenge hết hạn. Dùng session opaque 7 ngày của ADR 009, revoke có hiệu lực request tiếp theo.

## Vận hành / giới hạn

Migration chỉ thêm enum/bảng/index/FK, không sửa dữ liệu user hoặc tiền. Cấu hình allowlist riêng cho từng môi trường. Google cần các client ID audience/azp thực sự dùng bởi native SDK; Apple dùng bundle ID hoặc Services ID. Giữ danh sách tối thiểu, không nhận audience/JWKS URL từ client. Hai provider có thể bật độc lập. Backend cần outbound tới `www.googleapis.com` và `appleid.apple.com`.

Task chỉ backend; chưa bật nút Google/Apple mobile, chưa cấu hình console/entitlement hoặc smoke với tài khoản thật. Session Freeva không tự thu hồi khi user revoke consent tại provider vì chưa có server notification; dùng logout/revoke của Freeva và expiry 7 ngày. OAuth-only account chưa hỗ trợ đặt/reset password, linking/unlinking hay recovery riêng; request reset vẫn trả generic accepted. Email-first hiện tại dẫn account đã tồn tại về login; mobile OAuth cần UX tiếp tục bằng provider trong task tiếp theo.

## Nguồn giao thức

- [Google: authenticate with a backend server](https://developers.google.com/identity/sign-in/web/backend-auth)
- [Apple: authenticating users with Sign in with Apple](https://developer.apple.com/documentation/signinwithapple/authenticating-users-with-sign-in-with-apple)
- [Apple: verifying a user](https://developer.apple.com/documentation/signinwithapple/verifying-a-user)
