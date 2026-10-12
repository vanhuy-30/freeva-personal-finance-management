# Security test Phase 1 — SEC-P1-001

Review trước store theo [security-review.md](../process/security-review.md), ngày 2026-10-12. Không chứa payload exploit. Cert pinning, khóa biometric bằng hardware key, audit append-only và edge/WAF không nằm trong task này.

## Checklist

| Mục | Kết quả | Bằng chứng |
|---|---|---|
| Authn | Session opaque, Argon2id, token email một lần, staff token không mở session user | [auth.integration-spec.ts](../../backend/api/test/auth.integration-spec.ts), [security.integration-spec.ts](../../backend/api/test/security.integration-spec.ts) |
| Authz | User chỉ đụng dữ liệu của mình; Bearer user không gọi được lookup staff | Suite HTTP ví, giao dịch, danh mục, báo cáo, sync, export; `POST /api/admin/user-lookups` trả 401 với session user |
| Secrets | Không commit secret; mobile không nhúng API secret; `AUTH_SECRET_KEY` bắt buộc 32 byte hex | [secrets.md](../infrastructure/secrets.md), [auth-crypto.ts](../../backend/api/src/modules/auth/infrastructure/auth-crypto.ts) |
| Log PII | Path cấm bị redact; HTTP serializer bỏ query/header/body; Sentry scrub trước khi gửi | [pii-log-checklist.md](pii-log-checklist.md), `pino-redact.spec.ts`, `http-request.serializer.spec.ts`, `scrub.spec.ts` |
| Export / xóa | Owner, `no-store`, audit fail closed, UUID audit còn sau khi user biến mất | [account.integration-spec.ts](../../backend/api/test/account.integration-spec.ts), [account-privacy.md](account-privacy.md) |
| Rate limit | 30/IP và 5/email/operation/15 phút, 429 + `Retry-After`, không lưu email/IP thô, không tin `X-Forwarded-For` | [auth-rate-limit.guard.ts](../../backend/api/src/modules/auth/auth-rate-limit.guard.ts), suite auth |
| Payload auth không hợp lệ | `email` không phải chuỗi hoặc dài hơn 1024 ký tự vẫn bị giới hạn theo IP trước validation; response và bảng rate limit không chứa email thô | [security.integration-spec.ts](../../backend/api/test/security.integration-spec.ts) |
| Helmet / CORS | Cùng hàm với runtime: `x-content-type-options`, `x-frame-options`, allowlist `CORS_ORIGINS`, không bật trust proxy | [configure-http.ts](../../backend/api/src/core/http/configure-http.ts) |
| Mobile transport | HTTPS, không theo redirect, không nhận URL có userinfo/query/fragment | `apps/mobile/test/features/auth/auth_api_test.dart` |

## Dependency audit

`pnpm audit --prod` ngày 2026-10-12, trước khi vá: 2 critical, 11 high, 9 moderate, 2 low.

Đã vá trong cùng major, không nâng Prisma hay Nest:

- `next` và `eslint-config-next` `16.3.3` → `16.3.8`.
- Override pnpm: `multer@2.4.0`, `proxy-addr@2.0.8`, `qs@6.16.0`, `brace-expansion@^5` `5.0.12`, `fast-uri@^3` `3.1.8`, `sharp@0.35.4` → `0.35.5`, `source-map-js@1.2.1` → `1.2.2`.

Sau khi vá còn 1 high: `deepmerge-ts@7.1.5` qua `@prisma/config` (Prisma 6). Bản vá nằm ở `deepmerge-ts` 8, là major bên trong tooling Prisma. Không nâng trong task này.

CI không thêm bước `pnpm audit` vì high còn lại sẽ làm job đỏ.

`fvm flutter pub outdated` (Flutter `3.47.0`) ngày 2026-10-12 không báo advisory. Có package mới hơn, gồm major ngoài constraint hiện tại (`go_router`, `local_auth`, `sentry_flutter`, …). Không nâng vì không có bản vá bảo mật tương thích bắt buộc. SDK `flutter` trên `PATH` (`3.24.1`) không chạy được lệnh này; dùng FVM.

## Residual còn trước store

- `email-step` cố ý cho biết email đã có account. Rate limit không chặn enumeration bằng timing hoặc nhiều IP.
- Abuse phân tán và rate limit ở edge/WAF chưa có. Sau proxy, nhiều user có thể chung bucket IP; app vẫn không tự tin `X-Forwarded-For`.
- Payload malformed được giới hạn ở app theo IP. Giới hạn trước khi request tới process (body quá lớn, flood mạng) thuộc edge.
- Biometric không gắn hardware key và không phát hiện đổi tập enrollment. Smoke Face ID/vân tay, Keychain/Keystore và recents cần thiết bị thật.
- Bảng audit chưa append-only. Failed login chưa ghi audit từng lần.
- Cert pinning để sau (`SEC-P1` trong [secrets.md](../infrastructure/secrets.md)).
- ToS/privacy và PDPD vẫn cần luật sư. File export trên thiết bị vẫn phụ thuộc khóa app.
- `deepmerge-ts` 7 còn high cho đến khi có bản Prisma không kéo major này.
