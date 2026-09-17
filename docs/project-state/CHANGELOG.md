# Changelog dự án

Nhật ký repo/process — không phải App Store release notes.

## 2026-09-17

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
