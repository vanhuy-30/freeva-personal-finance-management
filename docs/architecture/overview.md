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

Xem ADR: monorepo, Flutter, NestJS, Next admin, Postgres, money/FX.

## Nguyên tắc

- Domain không phụ thuộc framework UI/HTTP.
- Một API cho mobile và admin; admin dùng role `staff`.
- OpenAPI là contract; client generate hoặc map thủ công có review.
- Feature flag server-side sớm (Phase 0 stub).

## Môi trường

Local compose → staging (TBD) → production (TBD). Chi tiết: [../infrastructure/environments.md](../infrastructure/environments.md).
