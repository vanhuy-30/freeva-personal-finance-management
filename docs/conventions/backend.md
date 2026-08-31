# Backend (NestJS)

- Module theo feature: `src/modules/{name}/`.
- Prisma chỉ ở infrastructure. Repository interface ở application/domain.
- DTO class-validator khớp OpenAPI.
- Money: `bigint` Prisma hoặc `Decimal` — không `Float`.
- Logger: Pino; paths trong `src/core/logging/pino-redact.ts` — [pii-log-checklist.md](../architecture/pii-log-checklist.md).
- Test: money helper + pino redact; e2e health.
