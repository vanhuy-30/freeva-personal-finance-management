# ADR 011 — Sentry crash monitoring

- **Status:** accepted
- **Date:** 2026-10-12
- **Deciders:** Freeva

## Context

Phase 0 đóng với residual crash monitoring (DECISIONS-OPEN #9): staging chỉ có health và log platform. Trước MVP cần stack crash trên API, web admin và mobile mà không gửi PII tài chính.

## Decision

Dùng Sentry cho crash staging (`INF-P1-001`).

- API (`@sentry/nestjs`), web admin (`@sentry/nextjs`) và mobile (`sentry_flutter`) chỉ khởi tạo khi có DSN. Local, test và CI không gửi event.
- DSN không commit. API/server admin dùng `SENTRY_DSN`. Crash trình duyệt admin dùng `NEXT_PUBLIC_SENTRY_DSN`. Mobile nhận DSN qua `--dart-define`, không ghi vào `config/staging.json`.
- Không tracing, không profile, không upload source map trong task này.
- Không endpoint smoke public. Script smoke chỉ gửi khi có cả DSN và `SENTRY_SMOKE=1` (mobile: `SENTRY_SMOKE=true` lúc khởi động).
- Trước khi gửi: bỏ user, body/header/cookie/query, biến local trong stack, và redact field cùng họ với log Pino cùng chuỗi email, `Bearer` và URL DSN. API không gửi HTTP status dưới 500.

## Consequences

SDK 11 phía JS dùng `dataCollection` để tắt user, cookie, header, body, query và biến stack. Flutter dùng `sentry_flutter` ≥9 (`sendDefaultPii: false`); 8.14.x không build với sentry-cocoa 8.58+ (`SentryBinaryImageCache.image`). Event trên dashboard chỉ xuất hiện sau khi người vận hành tạo project Sentry và đặt DSN. Production host chưa chốt; vendor crash staging là Sentry.
