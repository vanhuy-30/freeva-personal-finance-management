# STATUS

- **Phase hiện tại:** 0 — backlog hoàn tất (24/24), phase gate pending
- **Cập nhật:** 2026-09-17
- **CI:** `INF-P0-002` done; cả ba job xanh trên `main`, [run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189).
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

## Backlog Phase 0

- 24/24 task done. Chưa chuyển sang Phase 1 cho đến khi phase gate/blocker được xử lý hoặc chấp nhận chính thức.

Chi tiết status từng ID: [tasks/phase-00.md](../../tasks/phase-00.md).

## Blocker

- Chưa có staging cloud, crash SaaS, region dữ liệu (xem DECISIONS-OPEN).

## Ghi chú

Nghiệp vụ ví/giao dịch **chưa** làm (Phase 1). Local: API `:4000`, Postgres compose `:5434`, admin `:3001`.
