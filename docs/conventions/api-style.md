# API style

- REST, JSON, `camelCase`.
- Resource số nhiều: `/users`, `/financial-accounts`, `/transactions`.
- Pagination: `cursor` hoặc `page`+`pageSize` (chốt khi `BE-P1`).
- Filtering query rõ ràng, không SQL leak.
- 401/403/404/409/422 nhất quán trong error envelope.
- OpenAPI bắt buộc với endpoint mới.
