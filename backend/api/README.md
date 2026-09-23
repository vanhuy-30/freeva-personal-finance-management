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

Staging (Render): [docs/infrastructure/staging.md](../../docs/infrastructure/staging.md), Blueprint `render.yaml` ở root. Migrate: `prisma:migrate:deploy`.

## Staff lookup (Phase 0)

`POST /api/admin/user-lookups` yêu cầu Bearer token tối thiểu 32 ký tự trong `STAFF_AUTH_TOKEN`; actor audit là UUID `STAFF_ACTOR_ID`. Đây là credential staff tối thiểu cho môi trường nội bộ, không phải user auth Phase 1. Không commit giá trị thật.

## Email auth / sessions — BE-P1-001, BE-P1-002

Thiết kế: [ADR 009](../../docs/architecture/adr/009-email-auth-sessions.md). Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml).

1. Apply migrations (`pnpm --filter @freeva/api prisma:migrate:deploy`). Migration thêm auth tables, chuẩn hóa email và seed VND nếu chưa có; dừng nếu legacy email collision.
2. Đặt `AUTH_SECRET_KEY` bằng kết quả `openssl rand -hex 32` trong `.env` local hoặc secret manager. Giữ cùng key cho mọi API instance, không commit.
3. Đặt `MAIL_PROVIDER=smtp`, `SMTP_HOST`, `SMTP_PORT`, `MAIL_FROM`; `SMTP_USER` + `SMTP_PASSWORD` nếu server yêu cầu. Staging dùng `MAIL_PROVIDER=resend`, `MAIL_FROM="Freeva <onboarding@resend.dev>"`, `SMTP_PORT=2465` và secret `RESEND_API_KEY`; xem [runbook email](../../docs/infrastructure/email.md). Local Compose Mailhog: localhost:1025, UI localhost:8025. Staging/prod bắt buộc TLS, không dùng Mailhog. App fail startup nếu thiếu key/SMTP config.
4. Register → login ngay; có thể lấy mã trong email để verify sau. Login không tự đánh dấu email đã xác thực. Email được gửi bởi outbox worker mỗi 5 giây; token không xuất hiện trong HTTP response hoặc log. SMTP lỗi sẽ retry mỗi phút tới expiry; đọc cảnh báo chung trong log để theo dõi lỗi gửi.
5. Login trả opaque Bearer 7 ngày, không refresh. `GET /api/v1/sessions` liệt kê phiên; `DELETE /api/v1/sessions/{sessionId}` thu hồi một phiên, `DELETE /api/v1/sessions` thu hồi tất cả; `POST /api/v1/auth/logout` thu hồi hiện tại. Reset password thu hồi mọi phiên atomically.

Rate limit `/auth/*`: mỗi operation 30/IP + 5/email/15 phút, cả request thành công, HTTP 429 + `Retry-After`. Không trust X-Forwarded-For mặc định. Sau reverse proxy phải kiểm chứng trusted proxy trước khi thay cấu hình, xem ADR 009.

Tests: `pnpm --filter @freeva/api test`, `pnpm --filter @freeva/api build`; PostgreSQL integration và migration upgrade: [test README](test/README.md#auth--be-p1-001-be-p1-002).
