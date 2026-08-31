# Security

Kiểm soát và nguyên tắc. Mô hình đe dọa sống: [threat-model.md](threat-model.md) (STRIDE, bề mặt Phase 0/1). Cập nhật threat model mỗi epic lớn hoặc khi thêm endpoint / client / bên thứ ba — xem [security-review.md](../process/security-review.md).

## Assets

Dữ liệu giao dịch, số dư, PII, session token, (sau này) bank token.

## Kiểm soát Phase 0/1

- TLS everywhere.
- Password hashing (Argon2id hoặc bcrypt cost cao) — Phase 1.
- Rate limit login/OTP.
- Session revoke.
- Helmet, CORS allowlist.
- Log redaction: email, token, amount, account numbers.
- App lock (PIN/biometrics) — client.
- Secrets chỉ env / secret manager, không git.

## Admin

Staff ≠ user. Mọi tra cứu PII audit. Least privilege.

Báo cáo lỗ hổng: `security@` TBD trong DECISIONS-OPEN.
