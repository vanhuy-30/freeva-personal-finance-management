# Environments

| Env | Mục đích | Data |
|---|---|---|
| local | Dev máy | Compose Postgres/Redis, fake mail |
| test | CI | SQLite hoặc Postgres service container |
| staging | Trước phát hành | Isolated, anonymized hoặc seed |
| production | User thật | Region **Việt Nam** (DECISIONS-OPEN #5) |

Local ports: API `4000`, admin `3001`, Postgres `5434` (container 5432), Redis `6379`, Mailhog UI `8025`.

Không trỏ local vào prod DB.
