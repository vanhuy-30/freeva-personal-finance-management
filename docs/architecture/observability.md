# Observability

## Local (Phase 0 scaffold)

- API logs JSON (Pino), redaction — [pii-log-checklist.md](pii-log-checklist.md).
- `GET /api/health` — liveness + kiểm tra DB.
- Compose: Postgres, Redis, Mailhog.

## Staging (sau Phase 0)

- Health: `GET /api/health` trên Render; admin Vercel đọc status.
- Log API: Pino JSON + redact (platform Render logs).
- Crash: Sentry trên API, web admin và mobile khi có DSN (`INF-P1-001`, [ADR 011](adr/011-sentry-crash-monitoring.md)). Không có DSN thì SDK không gửi. Không tracing.

## Trước phát hành MVP

- Crash staging đã gắn SDK. Event live trên dashboard cần DSN do người vận hành đặt — [staging.md](../infrastructure/staging.md).
- Tracing request id.
- Uptime staging.
- Alert lỗi 5xx / sync fail rate.

Không log PII hay số tiền. Chi tiết field cấm / cho phép và cách rà PR: [pii-log-checklist.md](pii-log-checklist.md).
