# @freeva/api

NestJS + Prisma. Phase 0: `GET /api/health`.

```bash
cp .env.example .env
# from repo root
make up
pnpm --filter @freeva/api prisma:generate
pnpm --filter @freeva/api prisma:migrate
make api
```

Money helpers: `src/core/money`. Schema: ADR 007 / `prisma/schema.prisma`.

## Staff lookup (Phase 0)

`POST /api/admin/user-lookups` yêu cầu Bearer token tối thiểu 32 ký tự trong `STAFF_AUTH_TOKEN`; actor audit là UUID `STAFF_ACTOR_ID`. Đây là credential staff tối thiểu cho môi trường nội bộ, không phải user auth Phase 1. Không commit giá trị thật.
