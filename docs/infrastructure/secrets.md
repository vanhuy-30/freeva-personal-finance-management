# Secrets

- Không commit `.env`. Dùng `.env.example` làm template.
- Local: file `.env` gitignored.
- CI: GitHub Actions secrets khi cần (chưa bắt buộc Phase 0).
- Staging: secret trên dashboard **Render** / **Vercel** — [staging.md](staging.md). Không commit token staff hay `DATABASE_URL`.
- Prod: secret manager / hoster (TBD tới Store). Rotate DB password, JWT, store keys.
- Mobile: không nhúng API secret; chỉ public URL + cert pinning sau này (`SEC-P1`).
- Staff P0: `STAFF_AUTH_TOKEN` tối thiểu 32 ký tự và `STAFF_ACTOR_ID` UUID trong API env. Token thật không đặt trong `NEXT_PUBLIC_*`, URL, local storage hay repo; rotate khi nghi lộ.
