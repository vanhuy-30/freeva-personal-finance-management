# STATUS

- **Phase hiện tại:** 1 — Phase 0 **closed** 2026-09-21
- **Cập nhật:** 2026-09-25
- **CI:** `INF-P0-002` done; cả ba job xanh trên `main`, [run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189).
- **Staging:** live — API [Render](https://freeva-api-staging.onrender.com) (`GET /api/health` → 200, `database` = up); admin [Vercel](https://freeva-personal-finance-management.vercel.app) đọc health staging. Stack: `render.yaml` + `apps/web-admin/vercel.json`. Prod hoster TBD tới Store (region VN).
- **Crash monitoring:** residual chấp nhận khi đóng P0 — vendor dự kiến **Sentry**, wiring = `INF-P1-001` (DECISIONS-OPEN #9). Staging dựa health + log platform cho đến khi gắn SDK.
- **Brand:** board + PNG trong `docs/brand/`; token/theme P0 done. Mobile `MOB-P1-010` done: launcher iOS/Android + symbol splash/home và l10n tagline. Admin `WA-P1-001` done: favicon từ app icon và lockup ở header.
- **Transfer QA:** `QA-P0-002` done; fixture JSON versioned + contract test cho cùng currency và FX exact. Ledger/rounding còn `BE-P1-005`.
- **Audit:** `BE-P0-004` schema done; `WA-P0-002` đã ghi `staff.user_lookup` fail closed. Chưa writer event khác hoặc bảo vệ sửa/xóa.
- **Staff lookup:** `WA-P0-002` done; exact email/UUID, response hồ sơ tối thiểu, opaque Bearer env + actor UUID, không dashboard/dữ liệu tài chính. Auth single-staff P0 phải thay trước production.
- **Mobile auth:** `MOB-P1-001` doing: email auth, secure session, PIN/biometric lock, privacy cover và quản lý phiên. Analyze + 33 tests + native builds pass; chờ E2E Resend staging và biometric thiết bị thực để đóng task. [Email runbook](../infrastructure/email.md). [Chi tiết](../architecture/mobile-auth.md).
- **Mobile profile:** `MOB-P1-002` done: locale/currency/IANA TZ/kỳ 1–28, API theo owner với version chống ghi đè, l10n và privacy gate. Analyze, Flutter tests, API build/tests và PostgreSQL integration pass. Chưa deploy/smoke native. [Chi tiết](../architecture/mobile-profile.md).
- **Mobile wallets:** `MOB-P1-003` done: danh sách/tạo/sửa bốn loại ví, tiền BigInt, sắp xếp/ẩn/khôi phục, version/clientId và privacy gate. Analyze và 11 tests mới pass; chưa native build/E2E staging. [Chi tiết](../architecture/mobile-wallets.md).
- **Mobile analytics:** `MOB-P0-004` done; catalog typed, debug logger local, `schema_version: 1`, không property tùy ý/PII và chưa có vendor SDK.
- **Backup/restore:** `BE-P0-005` done; [runbook và bằng chứng local](../../infra/runbooks/backup-restore.md), PostgreSQL 16.14. Production PITR/retention/RPO/RTO chưa triển khai.
- **Scaffold:** xong trên `main` (`153d3e7`). Health API, admin placeholder, Flutter shell, docs, compose.
- **Financial accounts:** `BE-P1-004` done: CRUD bốn loại ví, số dư derived bigint, credit config, sắp xếp/lưu trữ/khôi phục, owner/version/clientId; 117 unit và 33 PostgreSQL integration tests, build/OpenAPI pass. Không migration mới; chưa deploy staging. [Thiết kế](../architecture/financial-accounts.md).
- **Data model:** `BE-P0-001` xong (ADR 007, Prisma lõi). CRUD ví đã có ở `BE-P1-004`; CRUD GD còn `BE-P1-005`.
- **Threat model:** `SEC-P0-001` xong ([threat-model.md](../architecture/threat-model.md)).
- **PII logs:** `SEC-P0-003` xong ([pii-log-checklist.md](../architecture/pii-log-checklist.md)).
- **Personas / use case ghi chi:** `PRD-P0-001` xong ([personas.md](../product/personas.md), [use-cases.md](../product/use-cases.md)).
- **ToS / privacy nháp:** `PRD-P0-002` xong ([terms-of-service.md](../legal/terms-of-service.md), [privacy-policy.md](../legal/privacy-policy.md)). Cần luật sư trước store.
- **Region dữ liệu:** chốt **Việt Nam** (DECISIONS-OPEN #5, 2026-09-18). Vendor hosting production cụ thể vẫn TBD tới Store.

## Backlog Phase 0

- **25/25 done.** `INF-P0-004` provision live verified 2026-09-21.

Chi tiết status từng ID: [tasks/phase-00.md](../../tasks/phase-00.md).

## Phase 0 gate — đã đóng (2026-09-21)

Theo [điều kiện hoàn thành Phase 0](../product/phases/phase-00.md) và [DECISIONS-OPEN](DECISIONS-OPEN.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P0 | Done (25/25) |
| Data model + security flow review | Done (ADR 007/008, threat model, PII checklist) |
| Backup/restore thử | Done local (`BE-P0-005`); production PITR chưa |
| Staging cloud | Done — `INF-P0-004`; URL ở mục Staging trên |
| Crash monitoring | **Residual chấp nhận** — Sentry dự kiến; SDK = `INF-P1-001` |
| Region dữ liệu | **Chốt VN** — DECISIONS-OPEN #5 (2026-09-18) |
| Logging JSON + redact | Done (`BE-P0-003` / `SEC-P0-003`) |
| PDPD / compliance skeleton | Có docs; luật sư trước store (không chặn foundation nếu chấp nhận nháp) |
| Prototype ghi thu chi với user | Không bắt buộc trong lần foundation này (Phase 1) |

Đóng theo option **B**: `INF-P0-004` xong + residual crash ghi rõ → mở Phase 1.

## Ghi chú

CRUD ví đã có; nghiệp vụ giao dịch còn `BE-P1-005`. Local: API `:4000`, Postgres compose `:5434`, admin `:3001`.
