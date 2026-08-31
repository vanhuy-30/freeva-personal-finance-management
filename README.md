# Freeva — quản lý tài chính cá nhân

Monorepo cho ứng dụng Freeva: **mobile (Flutter)**, **backend (NestJS)**, **web admin (Next.js)**.

Vòng lặp giá trị cốt lõi: **đăng ký → tạo ví → ghi giao dịch → xem số dư / báo cáo**.

## Cấu trúc

| Path | Vai trò |
|---|---|
| [apps/mobile](apps/mobile) | Flutter iOS + Android |
| [apps/web-admin](apps/web-admin) | Next.js — quản trị nội bộ |
| [backend/api](backend/api) | NestJS + Prisma + PostgreSQL |
| [packages/api-contracts](packages/api-contracts) | OpenAPI (source of truth) |
| [packages/design-tokens](packages/design-tokens) | Màu brand + semantic |
| [docs](docs) | Product, architecture, convention, project state |
| [tasks](tasks) | Backlog có prefix `BE` / `MOB` / `WA` / … |
| [infra/compose](infra/compose) | Postgres, Redis, Mailhog (local) |

## Yêu cầu máy local

- Node.js 22+, pnpm
- Flutter (stable) + Xcode / Android SDK khi chạy mobile
- Docker Desktop (Postgres / Redis)

## Khởi động

```bash
cp .env.example backend/api/.env   # hoặc export DATABASE_URL
make bootstrap
make up                            # postgres :5434, redis :6379, mailhog :8025
make api                           # API http://localhost:4000/api/health
make admin                         # admin http://localhost:3001
make mobile                        # Flutter
make health
```

Tài liệu bắt đầu từ [docs/README.md](docs/README.md). Trạng thái dự án: [docs/project-state/STATUS.md](docs/project-state/STATUS.md). Quy tắc AI/dev: [AGENTS.md](AGENTS.md).

## Task ID

Mọi công việc dùng prefix `{AREA}-P{phase}-{nnn}` (ví dụ `MOB-P1-004`). Xem [tasks/README.md](tasks/README.md).
