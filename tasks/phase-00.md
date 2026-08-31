# Phase 0 — tasks

Cập nhật 2026-08-31: scaffold + `BE-P0-001` + `SEC-P0-001` + `SEC-P0-003` (PII log checklist). Còn PRD, audit/backup/`INF-P0-002`.

## PRD / DOC

### PRD-P0-001 — Persona, thị trường VN, use case ưu tiên
- Status: todo
- DoD: personas.md không còn “chỉ stub”; 3 use case ghi chi được viết
- Note: file hiện là bản đầu + câu hỏi mở

### PRD-P0-002 — Draft ToS và privacy policy
- Status: todo
- Module: 21
- DoD: bản nháp tiếng Việt; danh sách bên thứ ba dự kiến

### DOC-P0-001 — Docs foundation (vision, modules, ADR, conventions)
- Status: done
- DoD: cây `docs/` theo IA

## SHD / DS / INF (scaffold)

### SHD-P0-001 — OpenAPI skeleton `/health`
- Status: done
- DoD: `packages/api-contracts/openapi.yaml`

### DS-P0-001 — Design tokens 5 màu brand + semantic + light/dark
- Status: done
- DoD: tokens.json + palette.md; Flutter/Next đọc token
- Note: Next import CSS variables. Flutter dùng `AppColors` (projection, hex không nằm trong widget)

### INF-P0-001 — Compose Postgres, Redis, Mailhog + Makefile
- Status: done
- DoD: `make up` chạy local; README compose
- Note: host Postgres `:5434` (tránh PG native `:5432`); API local `:4000`

### INF-P0-002 — CI Flutter analyze + Nest test/build + Next lint/build
- Status: todo
- DoD: workflow xanh trên `main`
- Note: [ci.yml](../.github/workflows/ci.yml) đã có; chưa confirm run GitHub (cần `gh auth` hoặc tab Actions)

### INF-P0-003 — `.env.example` và quy tắc secrets
- Status: done

## BE

### BE-P0-001 — Thiết kế mô hình dữ liệu user, ví, GD, category, currency
- Status: done
- Module: nền tảng, 20
- Depends: —
- DoD: ADR + ER trong data-model.md reviewed; money = integer minor units; timezone documented
- Note: ADR 007 + ER; Prisma BigInt minor units; chưa CRUD/seed (Phase 1)

### BE-P0-002 — Health API + Prisma migrate local
- Status: done
- DoD: `GET /api/health` 200 khi compose up; check DB

### BE-P0-003 — Logger JSON + redaction PII
- Status: done
- DoD: không log authorization/email/amount
- Note: Pino redact paths; checklist formal = `SEC-P0-003` (done)

### BE-P0-004 — Khung audit log (schema, chưa gắn hết event)
- Status: todo
- Module: 22, 26

### BE-P0-005 — Chiến lược backup/restore Postgres
- Status: todo
- Module: 20
- DoD: runbook đã chạy thử dump/restore local
- Note: runbook có; chưa chứng minh restore trên máy này

## MOB

### MOB-P0-001 — App shell: DI, logger, l10n vi/en, router
- Status: done
- DoD: splash + home placeholder; `flutter analyze` sạch

### MOB-P0-002 — Theme từ design tokens (light/dark)
- Status: done
- Module: DS
- DoD: không hex trong widget

### MOB-P0-003 — Feature flag client stub
- Status: done
- DoD: interface + local overlay; chưa remote
- Note: `LocalFeatureFlagService` luôn `false`; chưa gắn UI

### MOB-P0-004 — Analytics event stub (không PII)
- Status: todo
- DoD: log debug funnel events

## WA

### WA-P0-001 — Admin placeholder + hiển thị API health
- Status: done
- Module: 26
- DoD: trang dùng CSS variables brand

### WA-P0-002 — Tra cứu tài khoản staff (phân quyền) — tối thiểu
- Status: todo
- Module: 26
- Depends: BE auth staff (Phase 1 có thể kéo sớm)
- DoD: không dashboard kinh doanh

## SEC

### SEC-P0-001 — Threat model skeleton + surface Phase 0/1
- Status: done
- Module: 22
- DoD: STRIDE + trust boundary; surface P0 as-built và P1 planned gắn task; residual trỏ DECISIONS-OPEN / RISKS
- Note: [docs/architecture/threat-model.md](../docs/architecture/threat-model.md)

### SEC-P0-002 — Helmet, CORS allowlist, validation pipe
- Status: done
- Depends: BE-P0-002

### SEC-P0-003 — Checklist che PII trong log
- Status: done
- Module: 22
- Depends: BE-P0-003
- DoD: checklist field cấm/cho phép; Pino nested paths; test không lộ giá trị thật
- Note: [pii-log-checklist.md](../docs/architecture/pii-log-checklist.md); `pino-redact.ts`

## QA

### QA-P0-001 — Money helper + test minor units / cộng trừ
- Status: done
- DoD: unit test API (và/hoặc Dart) pass

### QA-P0-002 — Spec bảng test transfer cân bằng (chưa ledger)
- Status: todo
- DoD: file ví dụ số trong `docs` hoặc `backend/api/test/fixtures`
