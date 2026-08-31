# ADR 001 — Monorepo folder layout

- **Status:** accepted
- **Date:** 2026-08-26

## Context

Cần mobile, backend, web admin, docs trong một repo để đồng bộ contract và brand.

## Decision

- `apps/mobile`, `apps/web-admin` — client.
- `backend/api` — NestJS (tách khỏi `apps/` vì deploy/secret khác).
- `packages/api-contracts`, `packages/design-tokens`.
- pnpm workspace cho JS/TS. Flutter không thuộc pnpm.
- Không Nx/Turborepo.

## Consequences

CI cần cả Node và Flutter SDK. Makefile điều phối.
