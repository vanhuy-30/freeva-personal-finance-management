# STATUS

- **Phase hiện tại:** 0 — backlog 24/24 done; phase gate pending
- **Cập nhật:** 2026-09-18
- **CI:** `INF-P0-002` done; cả ba job xanh trên `main`, [run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189).
- **Brand:** board + PNG trong `docs/brand/`; token/theme P0 done. Gắn logo/icon = Phase 1 (`MOB-P1-010`, `WA-P1-001`).
- **Transfer QA:** `QA-P0-002` done; fixture JSON versioned + contract test cho cùng currency và FX exact. Ledger/rounding còn `BE-P1-005`.
- **Audit:** `BE-P0-004` schema done; `WA-P0-002` đã ghi `staff.user_lookup` fail closed. Chưa writer event khác hoặc bảo vệ sửa/xóa.
- **Staff lookup:** `WA-P0-002` done; exact email/UUID, response hồ sơ tối thiểu, opaque Bearer env + actor UUID, không dashboard/dữ liệu tài chính. Auth single-staff P0 phải thay trước production.
- **Mobile analytics:** `MOB-P0-004` done; catalog typed, debug logger local, `schema_version: 1`, không property tùy ý/PII và chưa có vendor SDK.
- **Backup/restore:** `BE-P0-005` done; [runbook và bằng chứng local](../../infra/runbooks/backup-restore.md), PostgreSQL 16.14. Production PITR/retention/RPO/RTO chưa triển khai.
- **Scaffold:** xong trên `main` (`153d3e7`). Health API, admin placeholder, Flutter shell, docs, compose.
- **Data model:** `BE-P0-001` xong (ADR 007, Prisma lõi). CRUD ví/GD là Phase 1.
- **Threat model:** `SEC-P0-001` xong ([threat-model.md](../architecture/threat-model.md)).
- **PII logs:** `SEC-P0-003` xong ([pii-log-checklist.md](../architecture/pii-log-checklist.md)).
- **Personas / use case ghi chi:** `PRD-P0-001` xong ([personas.md](../product/personas.md), [use-cases.md](../product/use-cases.md)).
- **ToS / privacy nháp:** `PRD-P0-002` xong ([terms-of-service.md](../legal/terms-of-service.md), [privacy-policy.md](../legal/privacy-policy.md)). Cần luật sư trước store.
- **Region dữ liệu:** chốt **Việt Nam** (DECISIONS-OPEN #5, 2026-09-18). Vendor hosting cụ thể vẫn TBD.

## Backlog Phase 0

- 24/24 task done. Chưa chuyển Phase 1 cho đến khi **phase gate** / blocker được xử lý hoặc chấp nhận chính thức (xem dưới).

Chi tiết status từng ID: [tasks/phase-00.md](../../tasks/phase-00.md).

## Phase gate / blocker (còn lại để đánh dấu Phase 0 xong)

Theo [điều kiện hoàn thành Phase 0](../product/phases/phase-00.md) và [DECISIONS-OPEN](DECISIONS-OPEN.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P0 | Done (24/24) |
| Data model + security flow review | Done (ADR 007/008, threat model, PII checklist) |
| Backup/restore thử | Done local (`BE-P0-005`); production PITR chưa |
| Staging cloud | **Chưa** — blocker |
| Crash monitoring (Sentry TBD) | **Chưa** — blocker; tool còn mở DECISIONS-OPEN #9 |
| Region dữ liệu | **Chốt VN** — DECISIONS-OPEN #5 (2026-09-18) |
| Logging JSON + redact | Done (`BE-P0-003` / `SEC-P0-003`) |
| PDPD / compliance skeleton | Có docs; luật sư trước store (không chặn foundation nếu chấp nhận nháp) |
| Prototype ghi thu chi với user | Không bắt buộc trong lần foundation này (Phase 1) |

**Cách đóng Phase 0:** (A) dựng staging + chọn crash tooling, hoặc (B) ghi quyết định chấp nhận residual (staging/crash) vào DECISIONS-OPEN / STATUS rồi mở Phase 1 chính thức.

## Ghi chú

Nghiệp vụ ví/giao dịch **chưa** làm (Phase 1). Local: API `:4000`, Postgres compose `:5434`, admin `:3001`.
