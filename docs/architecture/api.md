# API

- Base: `/api`. Version prefix khi breaking: `/api/v1` (bắt đầu gắn từ Phase 1 auth).
- Scaffold: `GET /api/health`.
- Source of truth: [packages/api-contracts/openapi.yaml](../../packages/api-contracts/openapi.yaml).
- Error envelope:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "…", "details": [] } }
```

- Money fields: string integer `amountMinor` + `currency`.
- Idempotency-Key header cho POST tạo giao dịch.
- Auth: Bearer (Phase 1). Admin: role staff riêng.

Workflow: sửa OpenAPI → PR cùng Nest DTO → client cập nhật.
