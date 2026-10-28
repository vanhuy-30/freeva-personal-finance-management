# AGENTS.md — Freeva rules for humans and AI

Personal-finance monorepo. Prefer **correct money, privacy, and layers** over shipping speed.

Agent workflow: [CLAUDE.md](CLAUDE.md). PR/DoD: [CONTRIBUTING.md](CONTRIBUTING.md). Stack detail: `docs/conventions/`.

## Before implementing a task

Each time you implement a task ID, state clearly up front (chat and PR summary):

1. **What the task is** — title + ID (e.g. `BE-P2-E01` / `MOB-P2-E01`).
2. **What the feature is in the product** — what the user can do in the app (or what the API enables).
3. **Why it exists** — product need, DoD, or dependency for later work.

Do not jump straight into file lists without that context. Prefer Vietnamese for product wording when the user writes in Vietnamese.

## Layout

| Path | Stack |
|---|---|
| `apps/mobile` | Flutter (iOS + Android; not for web admin) |
| `apps/web-admin` | Next.js App Router (internal) |
| `backend/api` | NestJS + Prisma |
| `packages/api-contracts` | OpenAPI — source of truth for public DTOs |
| `packages/design-tokens` | Brand colors — no ad-hoc hex in UI |
| `docs/` | Product + architecture |
| `tasks/` | Backlog — every PR cites a task ID |

## Invariants

- **Money:** integer minor units or `Decimal`; never `double`/`float`. Transfers = two balanced legs. FX stores rate + timestamp.
- **PII:** never log balances, account numbers, full emails, or tokens.
- **Mobile:** clean domain (no Flutter); Views do not call repositories; l10n + tokens. → [docs/conventions/flutter.md](docs/conventions/flutter.md)
- **Backend:** domain interfaces must not depend on Prisma; public endpoints ship with OpenAPI in the same PR. → [docs/conventions/backend.md](docs/conventions/backend.md)
- **UI:** colors only from `packages/design-tokens`. → [docs/brand/README.md](docs/brand/README.md)
- **Tasks:** `{PREFIX}-P{phase}-{nnn}` (`BE` `MOB` `WA` `INF` `DOC` `SEC` `DS` `QA` `SHD` `PRD`). Commit `feat(MOB-P1-004): …`. → [tasks/README.md](tasks/README.md)

## Do not

- Invent timelines, bank partners, or IAP.
- Add Nx/Turborepo unless a new ADR says so.
- Commit secrets or bypass auth “because local”.
