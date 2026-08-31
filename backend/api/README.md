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

Money helpers: `src/core/money`. Schema tài chính: `BE-P0-001`.
