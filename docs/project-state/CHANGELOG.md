# Changelog dự án

Nhật ký repo/process — không phải App Store release notes.

## 2026-09-21

- `BE-P1-001`, `BE-P1-002`: auth `/api/v1` email/password (Argon2id), verify/reset single-use, encrypted SMTP outbox/retry; opaque session 7 ngày, list/revoke/logout, rate limit PostgreSQL IP/email. Reset/session mutations khóa User và audit cùng transaction. Migration + OpenAPI + ADR 009/threat model/runbook/CI cập nhật. 37 unit + 12 HTTP/PostgreSQL tests, upgrade/collision regression và SMTP Mailhog smoke pass. Chưa deploy; cần AUTH_SECRET_KEY/SMTP trước rollout. Dependency audit hiện hữu còn 4 high, ghi trong threat model.

- `MOB-P1-010` splash: motion ba nhịp từ PNG gốc trong 1,8 giây, halo nhẹ và thu nhỏ/fade out; copy mới “Your money. Your freedom.”, hỗ trợ giảm chuyển động và chữ lớn.

- `MOB-P1-010`: gắn AppIcon iOS, launcher legacy/adaptive Android từ PNG chính thức; symbol nguyên bản cho splash Flutter/home, wordmark/tagline qua l10n. Thêm script tái sinh asset từ source + token; analyze và widget tests pass. Chưa smoke test launcher trên device/simulator.

- `INF-P0-004`: provision staging live — API Render `https://freeva-api-staging.onrender.com` (health + DB up), admin Vercel `https://freeva-personal-finance-management.vercel.app`; checklist [staging.md](../infrastructure/staging.md) tick; URL ghi STATUS.
- **Phase 0 closed** (option B): residual crash monitoring chấp nhận — vendor dự kiến Sentry, SDK = `INF-P1-001` (DECISIONS-OPEN #9). Backlog P0 = 25/25; mở Phase 1.

## 2026-09-18

- Staging: chốt stack **Render** (API+Postgres) + **Vercel** (web-admin); thêm `render.yaml`, `apps/web-admin/vercel.json`, [staging.md](../infrastructure/staging.md), task `INF-P0-004`. Production hoster vẫn TBD tới Store (region VN).
- DECISIONS-OPEN #5: chốt region dữ liệu production primary **Việt Nam**; cập nhật privacy/ToS nháp, ADR 005, environments, threat model, STATUS.
- Brand: chốt UI design system board (`docs/brand/ui-design-system.png`); thêm `docs/brand/README.md` (logo, tagline, palette tóm tắt)
- Brand: thêm asset PNG từ board — `freeva-brand-symbol.png`, `freeva-logo-lockup.png`, `freeva-app-icon.png`; cập nhật `docs/brand/README.md`.
- Backlog: brand asset → Phase 1 (`MOB-P1-010`, `WA-P1-001`); Phase 0 = 24/25 (còn staging provision).

## 2026-09-17

- `QA-P0-002`: thêm fixture JSON versioned và Jest contract test cho transfer hai leg cân bằng, lỗi cấu trúc/dấu/group/type và FX exact; ghi rõ rounding/ledger còn `BE-P1-005`. Phase 0 backlog đạt 24/24; phase gate vẫn pending theo STATUS.

- `WA-P0-002`: thêm `POST /api/admin/user-lookups` và form Next admin; opaque Bearer staff từ env, exact lookup email/UUID, response hồ sơ tối thiểu, không dashboard/dữ liệu tài chính. Ghi `staff.user_lookup` cho success/không tìm thấy và fail closed khi audit lỗi. OpenAPI/threat model/docs cập nhật; single-staff credential chỉ dùng P0 nội bộ. Phase 0 đạt 23/24.

- `MOB-P0-004`: thêm Flutter `AnalyticsService`/debug implementation qua DI; catalog event typed với payload `schema_version: 1`, chỉ cho phép `transaction_created.type` theo enum và không nhận property tùy ý/PII. Chưa gắn vendor SDK hoặc phát event giả từ UI placeholder. Phase 0 đạt 22/24.

- `BE-P0-005`: sửa runbook restore vào database mới; thêm diễn tập tự dọn container/backup tạm. PostgreSQL 16.14 pass dump/restore, so sánh schema/toàn bộ dữ liệu và migration history, audit constraints và Prisma migration status. Phase 0 đạt 21/24; production backup policy còn mở.

- `BE-P0-004`: thêm schema/migration `AuditEvent`, CHECK actor/mã thao tác và index; ADR 008, data model, threat model. Kiểm chứng fresh deploy, upgrade bảo toàn dữ liệu và SQL regression trên PostgreSQL 16.14. Chưa service ghi event, integration, retention hoặc chống sửa/xóa.

## 2026-09-16

- `INF-P0-002`: xác minh ba job CI xanh trên `main` tại `e72ac63` ([run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189), chạy 2026-09-01). Cập nhật backlog thành done và ghi bằng chứng trong `docs/infrastructure/ci-cd.md`; không thay đổi workflow.

## 2026-09-01

- `PRD-P0-002`: bản nháp tiếng Việt Điều khoản dịch vụ và Chính sách bảo mật (`docs/legal/`); danh sách bên thứ ba dự kiến (không đặt tên bank/IAP; vendor/region TBD). Chưa review luật sư; export/xóa TK vẫn `BE-P1-010`.
- `PRD-P0-001`: persona P1 knowledge worker (beta 100%), thị trường VN, store listing 22–35; hộ gia đình giữ Phase 6 + workaround category/tag. Ba use case ghi chi UC-EXP-01/02/03 (`docs/product/use-cases.md`).

## 2026-08-31

- `SEC-P0-003`: checklist PII trong log (`docs/architecture/pii-log-checklist.md`); Pino redact nested 1–2 cấp + test hồi quy.
- `SEC-P0-001`: threat model STRIDE + inventory bề mặt Phase 0/1 (`docs/architecture/threat-model.md`).
- `BE-P0-001`: ADR 007 + ER; Prisma schema lõi (User, Currency, ví, danh mục, GD, FX, tag). Money = BigInt minor units. Chưa CRUD/seed.
- Dọn backlog Phase 0 cho khớp code: scaffold `done`; còn lại product/`INF-P0-002`.

## 2026-08-26

- Khởi tạo monorepo: docs, tasks, design tokens, compose, Nest health, Next admin, Flutter shell, CI.
