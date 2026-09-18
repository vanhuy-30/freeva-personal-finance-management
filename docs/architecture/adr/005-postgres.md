# ADR 005 — PostgreSQL

- **Status:** accepted
- **Date:** 2026-08-26

## Decision

PostgreSQL 16 làm source of truth. Redis cho queue/cache/session sau này. Local qua Docker Compose.

Region dữ liệu production primary: **Việt Nam** — [DECISIONS-OPEN](../../project-state/DECISIONS-OPEN.md) #5 (chốt 2026-09-18). Vendor hosting production cụ thể chốt khi Store.

Staging: Render (API+Postgres, region Singapore trên platform) + Vercel (admin) — [staging.md](../../infrastructure/staging.md).
