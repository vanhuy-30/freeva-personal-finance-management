# STATUS

- **Phase hiện tại:** 0 — nền tảng
- **Cập nhật:** 2026-09-01
- **Scaffold:** xong trên `main` (`153d3e7`). Health API, admin placeholder, Flutter shell, docs, compose.
- **Data model:** `BE-P0-001` xong (ADR 007, Prisma lõi). CRUD ví/GD là Phase 1.
- **Threat model:** `SEC-P0-001` xong ([threat-model.md](../architecture/threat-model.md)).
- **PII logs:** `SEC-P0-003` xong ([pii-log-checklist.md](../architecture/pii-log-checklist.md)).
- **Personas / use case ghi chi:** `PRD-P0-001` xong ([personas.md](../product/personas.md), [use-cases.md](../product/use-cases.md)).

## Còn lại Phase 0 (làm trên branch mới)

1. `PRD-P0-002` — draft ToS/privacy
2. `BE-P0-004` / `BE-P0-005` — audit schema + thử backup/restore
3. `MOB-P0-004`, `QA-P0-002`, `WA-P0-002`
4. `INF-P0-002` — confirm CI GitHub xanh

Chi tiết status từng ID: [tasks/phase-00.md](../../tasks/phase-00.md).

## Blocker

- Chưa có staging cloud, crash SaaS, region dữ liệu (xem DECISIONS-OPEN).

## Ghi chú

Nghiệp vụ ví/giao dịch **chưa** làm (Phase 1). Local: API `:4000`, Postgres compose `:5434`, admin `:3001`.
