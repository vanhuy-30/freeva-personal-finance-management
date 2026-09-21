# Observability

## Local (Phase 0 scaffold)

- API logs JSON (Pino), redaction — [pii-log-checklist.md](pii-log-checklist.md).
- `GET /api/health` — liveness + kiểm tra DB.
- Compose: Postgres, Redis, Mailhog.

## Staging (sau Phase 0)

- Health: `GET /api/health` trên Render; admin Vercel đọc status.
- Log API: Pino JSON + redact (platform Render logs).
- Crash SaaS: residual tới `INF-P1-001` (Sentry dự kiến — DECISIONS-OPEN #9).

## Trước phát hành MVP

- Crash: Sentry (`INF-P1-001`) trên API ± admin ± mobile staging.
- Tracing request id.
- Uptime staging.
- Alert lỗi 5xx / sync fail rate.

Không log PII hay số tiền. Chi tiết field cấm / cho phép và cách rà PR: [pii-log-checklist.md](pii-log-checklist.md).
