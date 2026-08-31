# Observability

## Local (Phase 0 scaffold)

- API logs JSON (Pino), redaction — [pii-log-checklist.md](pii-log-checklist.md).
- `GET /api/health` — liveness + kiểm tra DB.
- Compose: Postgres, Redis, Mailhog.

## Trước phát hành MVP

- Crash: Sentry hoặc tương đương (`INF-P1`).
- Tracing request id.
- Uptime staging.
- Alert lỗi 5xx / sync fail rate.

Không log PII hay số tiền. Chi tiết field cấm / cho phép và cách rà PR: [pii-log-checklist.md](pii-log-checklist.md).
