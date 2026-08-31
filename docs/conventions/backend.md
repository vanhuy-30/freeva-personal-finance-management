# Backend (NestJS)

- Module theo feature: `src/modules/{name}/`.
- Prisma chỉ ở infrastructure. Repository interface ở application/domain.
- DTO class-validator khớp OpenAPI.
- Money: `bigint` Prisma hoặc `Decimal` — không `Float`.
- Logger: Pino, redact paths email, authorization, amountMinor.
- Test: money helper + usecase; e2e health.
