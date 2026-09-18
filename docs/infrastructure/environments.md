# Environments

| Env | Mục đích | Data / host |
|---|---|---|
| local | Dev máy | Compose Postgres/Redis, fake mail |
| test | CI | SQLite hoặc Postgres service container |
| staging | Trước phát hành | API+Postgres **Render**, admin **Vercel** — [staging.md](staging.md). Data isolated/seed; không user thật |
| production | User thật | Region **Việt Nam** (DECISIONS-OPEN #5). Vendor hoster **chốt khi chuẩn bị Store** |

Local ports: API `4000`, admin `3001`, Postgres `5434` (container 5432), Redis `6379`, Mailhog UI `8025`.

Không trỏ local vào prod DB. Không trỏ local admin vào staging DB có PII (staging cũng không nên có PII thật).
