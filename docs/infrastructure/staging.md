# Staging

Môi trường trước phát hành: **API + Postgres trên Render**, **web-admin trên Vercel**.

| Thành phần | Host | Ghi chú |
|---|---|---|
| Nest API (`@freeva/api`) | [Render](https://render.com) Web Service | Blueprint [render.yaml](../../render.yaml) |
| Postgres | Render PostgreSQL | Cùng Blueprint; chỉ data staging / seed |
| Web admin (`@freeva/web-admin`) | [Vercel](https://vercel.com) | Root Directory `apps/web-admin` + [vercel.json](../../apps/web-admin/vercel.json) |
| Mobile | Không deploy store staging trong task này | Trỏ `API_BASE` thủ công khi cần |

**Không** dùng staging làm production. **Vendor hosting production** (đúng region VN) chốt khi chuẩn bị release Store — [DECISIONS-OPEN](../project-state/DECISIONS-OPEN.md) #4 / #5.

Render hiện không có region Việt Nam; Blueprint dùng `singapore` (gần VN). Chấp nhận cho **staging** (không user thật). Production primary vẫn **Việt Nam**.

Redis: chưa runtime-dependent ở P0 — không provision trên staging.

## Điều kiện hoàn thành (`INF-P0-004`)

Verified 2026-09-21 — task **done**.

- [x] Blueprint Render tạo được service + DB; `GET /api/health` → 200, `database` = up.
- [x] Vercel deploy admin; trang health hiển thị status từ API staging.
- [x] `CORS_ORIGINS` = URL Vercel; `NEXT_PUBLIC_API_BASE_URL` = URL Render (HTTPS, không slash cuối).
- [x] `STAFF_AUTH_TOKEN` (≥32) + `STAFF_ACTOR_ID` (UUID) chỉ trên Render dashboard — không commit, không `NEXT_PUBLIC_*`.
- [x] URL staging ghi vào [STATUS](../project-state/STATUS.md).

| Thành phần | URL staging |
|---|---|
| API | https://freeva-api-staging.onrender.com |
| Web admin | https://freeva-personal-finance-management.vercel.app |

## Provision Render (API)

1. Tài khoản Render → **New** → **Blueprint** → chọn repo, file `render.yaml`.
2. Tạo service + DB theo Blueprint.
3. Dashboard API → Environment:
   - `CORS_ORIGINS` = `https://<vercel-admin-host>` (bước Vercel có host).
   - `STAFF_AUTH_TOKEN` = secret ngẫu nhiên ≥32 ký tự.
   - `STAFF_ACTOR_ID` = UUID v4 ổn định cho staging (khác prod sau này).
4. Deploy; mở `https://<api-host>/api/health`.
5. Migrate chạy trong `startCommand` (`prisma migrate deploy`). Lỗi migrate → xem log Render, không chạy migrate prod từ máy local vào staging trừ khi cố ý.

Free plan có thể sleep — health lần đầu chậm là bình thường.

## Provision Vercel (admin)

1. Import repo trên Vercel.
2. **Root Directory:** `apps/web-admin` (bật include files ngoài root nếu UI hỏi — cần `@freeva/design-tokens`).
3. Framework: Next.js; dùng `installCommand` / `buildCommand` trong `vercel.json`.
4. Env:
   - `NEXT_PUBLIC_API_BASE_URL` = `https://<render-api-host>` (không `/api` đuôi; app gọi `/api/health`).
5. Deploy Preview hoặc Production project riêng tên `freeva-admin-staging`.
6. Copy URL → cập nhật `CORS_ORIGINS` trên Render → redeploy API nếu cần.

Staff token cho form lookup: nhập tay trên UI khi gọi API; không nhúng vào build Vercel.

## Biến môi trường (checklist)

| Biến | Ở đâu | Ghi chú |
|---|---|---|
| `DATABASE_URL` | Render (từ DB) | Blueprint gắn sẵn |
| `PORT` | Render | Platform set; app đọc `process.env.PORT` |
| `CORS_ORIGINS` | Render | Origin Vercel |
| `STAFF_AUTH_TOKEN` / `STAFF_ACTOR_ID` | Render | Secrets |
| `NODE_ENV` | Render | `staging` |
| `NEXT_PUBLIC_API_BASE_URL` | Vercel | Public URL API |

Template local: [backend/api/.env.example](../../backend/api/.env.example), [apps/web-admin/.env.example](../../apps/web-admin/.env.example).

## Bảo mật staging

- Không seed PII user thật; chỉ tài khoản thử.
- Health public chấp nhận P0; trước khi public rộng xem [threat-model.md](../architecture/threat-model.md).
- Không commit secret; rotate khi nghi lộ — [secrets.md](secrets.md).

## CD

Chưa bắt buộc GitHub Actions deploy. Render/Vercel gắn git `main` (hoặc branch `staging`) là đủ Phase 0. CI vẫn là [ci-cd.md](ci-cd.md).

## Phase 1 auth configuration

`BE-P1-001` / `BE-P1-002`: trước deploy đặt `AUTH_SECRET_KEY` (64 hex ngẫu nhiên từ `openssl rand -hex 32`), `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM`, và cặp `SMTP_USER`/`SMTP_PASSWORD` nếu SMTP yêu cầu. Blueprint khai báo các env, không chứa secret/vendor. SMTP ở staging bắt buộc TLS; migrate trước start như hiện tại. Free instance ngủ làm outbox gửi chậm; job giữ đến expiry và retry khi app chạy. Rate limit lấy socket IP mặc định, có thể gom nhiều user sau proxy; kiểm chứng trusted proxy topology trước thay cấu hình. Xem [ADR 009](../architecture/adr/009-email-auth-sessions.md).
