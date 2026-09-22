# Security

Kiểm soát và nguyên tắc. Mô hình đe dọa sống: [threat-model.md](threat-model.md) (STRIDE, bề mặt Phase 0/1). Cập nhật threat model mỗi epic lớn hoặc khi thêm endpoint / client / bên thứ ba — xem [security-review.md](../process/security-review.md).

## Assets

Dữ liệu giao dịch, số dư, PII, session token, (sau này) bank token.

## Kiểm soát Phase 0/1

- TLS everywhere.
- Password hashing Argon2id; verify/reset token single-use; [ADR 009](adr/009-email-auth-sessions.md).
- Rate limit PostgreSQL theo IP/email, 429 + Retry-After; không trust forwarded IP mặc định.
- Opaque Bearer session 7 ngày, revoke DB; reset password thu hồi toàn bộ phiên.
- Helmet, CORS allowlist.
- Log redaction: email, token, amount, account numbers — checklist [pii-log-checklist.md](pii-log-checklist.md).
- App lock (PIN/biometrics) — client.
- Secrets chỉ env / secret manager, không git.

## Admin

Staff ≠ user. Mọi tra cứu PII audit. Least privilege.

P0 (`WA-P0-002`): credential Bearer opaque tối thiểu 32 ký tự nằm trong secret env, ánh xạ một UUID staff để audit. Endpoint chỉ cho tìm chính xác theo email/UUID, trả hồ sơ tối thiểu và fail closed nếu không ghi được audit. Credential thật không được commit/log/lưu browser. Cơ chế single-staff này chỉ là nền nội bộ; identity/session/revoke nhiều staff phải thay thế trước production.

Báo cáo lỗ hổng: `security@` TBD trong DECISIONS-OPEN.
