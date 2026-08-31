# Secrets

- Không commit `.env`. Dùng `.env.example` làm template.
- Local: file `.env` gitignored.
- CI: GitHub Actions secrets khi cần (chưa bắt buộc Phase 0).
- Prod: secret manager (TBD). Rotate DB password, JWT, store keys.
- Mobile: không nhúng API secret; chỉ public URL + cert pinning sau này (`SEC-P1`).
