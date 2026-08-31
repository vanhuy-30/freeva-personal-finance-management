# STATUS

- **Phase hiện tại:** 0 — nền tảng
- **Cập nhật:** 2026-08-31
- **Scaffold:** xong trên `main` (`153d3e7`). Health API, admin placeholder, Flutter shell, docs, compose.

## Còn lại Phase 0 (làm trên branch mới)

1. `BE-P0-001` — mô hình dữ liệu (Prisma/ER review)
2. `SEC-P0-001` + `SEC-P0-003` — threat model + checklist PII
3. `PRD-P0-001` / `PRD-P0-002` — persona chốt + draft ToS/privacy
4. `BE-P0-004` / `BE-P0-005` — audit schema + thử backup/restore
5. `MOB-P0-004`, `QA-P0-002`, `WA-P0-002`
6. `INF-P0-002` — confirm CI GitHub xanh

Chi tiết status từng ID: [tasks/phase-00.md](../../tasks/phase-00.md).

## Blocker

- Chưa có staging cloud, crash SaaS, region dữ liệu (xem DECISIONS-OPEN).
- Không chặn bắt đầu `BE-P0-001`.

## Ghi chú

Nghiệp vụ ví/giao dịch **chưa** làm (Phase 1). Local: API `:4000`, Postgres compose `:5434`, admin `:3001`.
