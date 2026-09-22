# ADR 009 — Email auth, opaque sessions, transactional mail outbox

- Status: accepted (implementation `BE-P1-001`, `BE-P1-002`)
- Date: 2026-09-21

## Context

Phase 1 cần email/password, verify/reset, logout, quản lý phiên và rate limit trên API NestJS. PostgreSQL đã là dependency bắt buộc. Chưa có quyết định JWT/refresh, SMTP vendor hoặc device identity.

## Decision

- Routes mới ở `/api/v1`; health và staff P0 giữ contract hiện có. Staff credential không dùng được làm user session.
- Email trim + lowercase, unique trong DB; không sửa password khi đăng ký trùng. Password 12–128 ký tự, không trim; Argon2id (19 MiB, 2 iterations, parallelism 1), salt ngẫu nhiên từng hash. Login kiểm tra dummy hash cho email không tồn tại.
- User được login bằng email/password ngay sau đăng ký, không bắt buộc verify email (quyết định sản phẩm cập nhật 2026-09-22). Login không tự đánh dấu email đã xác thực; trạng thái emailVerifiedAt chỉ thay đổi khi consume verify token. Token email ngẫu nhiên 256 bit, lưu SHA-256; verify 24 giờ, reset 30 phút, một lần, tách purpose. Resend thay token cũ. Reset không tự verify email hay auto-login.
- Session opaque 256 bit, chỉ lưu SHA-256, hết hạn tuyệt đối sau 7 ngày. Trả token duy nhất lúc login; client lưu secure storage. Không refresh/sliding expiry trong hai task này: hết hạn thì login lại. Guard query DB mỗi request, revoke có hiệu lực ở request tiếp theo; request đã qua guard có thể hoàn thành.
- List phiên trả UUID/thời điểm/current; không lưu IP, user agent hay device name. DELETE một phiên hoặc toàn bộ chỉ tác động user hiện tại, response 204 idempotent cho ID không tồn tại/không sở hữu. Logout thu hồi phiên hiện tại.
- Reset đổi hash, xóa mọi phiên/token email/outbox của user trong một transaction. Mutations khóa hàng User trước; login kiểm tra lại hash sau khóa để không tạo phiên từ password đã bị reset.
- Rate limit PostgreSQL atomic upsert: mỗi operation 30 request/IP và 5 request/email chuẩn hóa trong 15 phút, tính cả thành công. Khóa HMAC, không lưu email/IP thô; TTL cleanup. Limit trước validation/hash; lỗi storage fail closed. Response 429 có Retry-After. Áp dụng toàn bộ `/auth/*`; endpoint session yêu cầu auth.
- Express không trust proxy mặc định; bỏ qua X-Forwarded-For. Khi đặt sau proxy, các user có thể cùng bucket IP của proxy. Phải cấu hình/kiểm chứng trusted proxy theo topology thực trước khi scale; không bật `trust proxy=true` đại trà.
- Đăng ký/request verify/reset trả 202 thống nhất dù email không tồn tại/đã tồn tại/không đủ điều kiện. Không trả token qua HTTP. Tạo token và mail job cùng transaction; SMTP lỗi không thay đổi response theo trạng thái account.
- Outbox lưu token mã hóa AES-256-GCM; key 32 byte `AUTH_SECRET_KEY` từ env, cũng dùng HMAC rate keys. Worker poll 5 giây, batch tối đa 10, claim `SKIP LOCKED` + lease 1 phút, retry đến khi token hết hạn. SMTP timeout, log chỉ mã/message chung, không payload. At-least-once: crash sau SMTP trước delete có thể gửi trùng; token vẫn dùng một lần.
- SMTP host/from bắt buộc. Ngoài development/test, bắt buộc TLS (STARTTLS hoặc implicit TLS :465). Không tự chọn vendor. Email chứa mã để nhập trong app, không URL chứa token; màn mobile thuộc `MOB-P1-001`.
- Audit success registration/verify/login/reset/revoke cùng transaction; chỉ actor/target UUID và action/outcome, không metadata PII. Register chưa chứng minh identity nên actor `system`. Audit hiện chưa append-only (ADR 008). Failed login được throttle, chưa ghi audit từng lần.
- Pino HTTP serializer chỉ method/path/request ID/remoteAddress; bỏ query/header/body. Redact tokenHash và encryptedToken nếu log có cấu trúc ở chỗ khác. Auth error filter không phản chiếu dữ liệu validation hay exception storage.

## Migration / operations

Migration transaction kiểm tra trùng email sau normalization và dừng nếu collision; không gộp identity. Existing user giữ nguyên financial data, nullable passwordHash/emailVerifiedAt; không tự cấp quyền hoặc password. Account legacy chưa có credential không thể dùng public auth để chiếm tài khoản; cần quy trình onboarding/recovery được duyệt riêng trước khi có legacy user thật. Seed VND nếu chưa có để thỏa FK User.defaultCurrencyCode.

Cleanup định kỳ xóa token/phiên/rate bucket/outbox đã hết hạn. Outbox thành công xóa ngay. Nếu API ngủ, delivery/cleanup tiếp tục khi instance chạy lại; không cam kết delivery latency trên free staging. Key phải giống nhau giữa instance và giữ ổn định qua restart. Rotate key làm outbox cũ không giải mã được, user cần request email mới; session hash không phụ thuộc key. Không log key, cần quản lý backup/rotation bằng secret manager.

## Consequences

Không thêm Redis runtime hay JWT signing/refresh rotation; đổi lại mọi auth request phụ thuộc DB. Khóa user đảm bảo reset/session consistency. Rate limit email có thể bị lợi dụng làm user phải chờ window; cửa sổ hữu hạn, không lock tài khoản vĩnh viễn. HTTP response không tiết lộ account existence nhưng timing/traffic analysis và abuse quy mô lớn vẫn cần review `SEC-P1-001`, cùng edge rate limit cho payload malformed trước controller.
