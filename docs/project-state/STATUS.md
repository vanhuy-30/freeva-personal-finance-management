# STATUS

- **Phase hiện tại:** 0 — nền tảng
- **Cập nhật:** 2026-09-16
- **CI:** `INF-P0-002` done; cả ba job xanh trên `main`, [run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189). Phase 0: 19/24 task done.
- **Scaffold:** xong trên `main` (`153d3e7`). Health API, admin placeholder, Flutter shell, docs, compose.
- **Data model:** `BE-P0-001` xong (ADR 007, Prisma lõi). CRUD ví/GD là Phase 1.
- **Threat model:** `SEC-P0-001` xong ([threat-model.md](../architecture/threat-model.md)).
- **PII logs:** `SEC-P0-003` xong ([pii-log-checklist.md](../architecture/pii-log-checklist.md)).
- **Personas / use case ghi chi:** `PRD-P0-001` xong ([personas.md](../product/personas.md), [use-cases.md](../product/use-cases.md)).
- **ToS / privacy nháp:** `PRD-P0-002` xong ([terms-of-service.md](../legal/terms-of-service.md), [privacy-policy.md](../legal/privacy-policy.md)). Cần luật sư trước store.

## Còn lại Phase 0 (làm trên branch mới)

1. `BE-P0-004` / `BE-P0-005` — audit schema + thử backup/restore
2. `MOB-P0-004`, `QA-P0-002`, `WA-P0-002`

Chi tiết status từng ID: [tasks/phase-00.md](../../tasks/phase-00.md).

## Blocker

- Chưa có staging cloud, crash SaaS, region dữ liệu (xem DECISIONS-OPEN).

## Ghi chú

Nghiệp vụ ví/giao dịch **chưa** làm (Phase 1). Local: API `:4000`, Postgres compose `:5434`, admin `:3001`.
