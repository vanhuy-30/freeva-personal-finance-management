# Hướng dẫn đóng góp

Đọc [docs/README.md](docs/README.md) và [docs/conventions/git.md](docs/conventions/git.md) trước khi mở PR.

## Luồng làm việc

1. Lấy task ID từ [tasks](tasks) (ví dụ `BE-P0-001`). Nếu chưa có, tạo task rồi mới code.
2. Branch: `feat/BE-P0-001-short-slug` hoặc làm việc trên `main` nếu team chốt trunk-based thuần (xem convention git).
3. Commit: `feat(BE-P0-001): mô tả ngắn`.
4. PR template bắt buộc nêu task ID, phase, DoD.
5. Không commit `.env`, secret, keystore.

## Definition of Done

Xem [docs/process/definition-of-done.md](docs/process/definition-of-done.md). Tóm tắt:

- Đúng layer (domain không import Flutter/Nest HTTP).
- Tiền: không `double` / `float` cho số tiền.
- Màu: chỉ từ design tokens.
- Chuỗi UI: l10n, không hardcode tiếng Việt/Anh trên widget.
- Test cho logic tiền / transfer khi đụng số dư.

## Stack

- Mobile: Flutter, Clean Architecture + MVVM, `get_it` + `injectable`, `dartz`.
- Backend: NestJS, Prisma, PostgreSQL.
- Web admin: Next.js App Router.
- Contract: `packages/api-contracts/openapi.yaml`.
