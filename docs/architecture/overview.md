# Architecture overview

```
apps/mobile (Flutter) ──┐
                        ├── packages/api-contracts (OpenAPI)
apps/web-admin (Next) ──┘
                        │
                        ▼
                 backend/api (NestJS)
                        │
            PostgreSQL + Redis (local: compose)
```

## Quyết định

Xem ADR: monorepo, Flutter, NestJS, Next admin, Postgres, money/FX, [core data model](adr/007-core-data-model.md).

## Nguyên tắc

- Domain không phụ thuộc framework UI/HTTP.
- Một API cho mobile và admin; admin dùng role `staff`.
- OpenAPI là contract; client generate hoặc map thủ công có review.
- Feature flag server-side sớm (Phase 0 stub).

## Môi trường

Local compose → staging (Render API + Vercel admin) → production (hoster TBD, region VN). Chi tiết: [../infrastructure/environments.md](../infrastructure/environments.md), [../infrastructure/staging.md](../infrastructure/staging.md).
