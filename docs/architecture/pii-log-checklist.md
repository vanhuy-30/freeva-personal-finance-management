# Checklist che PII trong log

`SEC-P0-003`. Catalog kiểm soát: [security.md](security.md). Config API: [`backend/api/src/core/logging/pino-redact.ts`](../../backend/api/src/core/logging/pino-redact.ts). Threat: T-I02 trong [threat-model.md](threat-model.md).

Pino chỉ che **đúng path** đã liệt kê. Nội suy PII vào chuỗi message **không** bị redact.

## Cấm (giá trị đầy đủ)

| Loại | Field / ví dụ | Ghi chú |
|---|---|---|
| Email | `email` | Redact hết; không mask một phần ở P0 |
| Mật khẩu | `password`, `passwordHash` | Kể cả Phase 1 auth |
| Token | `Authorization`, `cookie`, `set-cookie`, `token`, `refreshToken`, `accessToken`, API key | Header HTTP + payload |
| Tiền / số dư | `amountMinor`, `initialBalanceMinor`, `creditLimitMinor`, `balanceMinor` | Mọi `*Minor` |
| Số tài khoản | `accountNumber`, `iban` | Chưa có trên schema P0; path sẵn cho P1+ |
| Secret env | `DATABASE_URL`, SMTP password, secret manager | Không log env |

## Cho phép

`userId` UUID, `requestId`, HTTP method / path / status, `remoteAddress` (retention IP ~90 ngày — [privacy-compliance.md](privacy-compliance.md)).

## Quy tắc chuỗi

Không viết `logger.info(\`user ${email}\`)` hay `AppLogger.info('amount $amountMinor')`. Redact path không bắt được nội dung trong message. Log field có cấu trúc; để Pino (API) hoặc không đưa PII vào chuỗi (client).

## Client

- Flutter: không `print()`. Không nhét email, số dư, số TK vào `AppLogger`.
- Web admin: không `console.log` payload user / PII.
- Analytics: catalog cấm email / số dư / số TK — `MOB-P0-004`.

## Giới hạn Pino

Wildcard một cấp (`*.email`). Path hai cấp (`*.*.email`) cho DTO lồng (`req.body.user.email`). Sâu hơn: thêm path khi có DTO mới, hoặc không log object đó.

## Rà PR

1. Field mới có trong bảng cấm? Thêm path (top-level + `*.` + `*.*.`) vào `pino-redact.ts` và test.
2. Endpoint auth, export, CRUD tiền: xác nhận object log không chứa giá trị thật (xem `pino-redact.spec.ts`).
3. Không nội suy PII vào message.
4. Reviewer: mục “Log không PII” trên PR template.

Cập nhật file này khi thêm loại dữ liệu nhạy cảm (bank token Phase 6, crash SaaS).
