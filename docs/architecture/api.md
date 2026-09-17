# API

- Base: `/api`. Version prefix khi breaking: `/api/v1` (bắt đầu gắn từ Phase 1 auth).
- Public scaffold: `GET /api/health`.
- Admin P0: `POST /api/admin/user-lookups`, Bearer staff, body chứa chính xác một trong `userId` / `email`; không đặt PII trong query string.
- Source of truth: [packages/api-contracts/openapi.yaml](../../packages/api-contracts/openapi.yaml).
- Error envelope:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "…", "details": [] } }
```

- Money fields: string integer `amountMinor` + `currency`.
- Idempotency-Key header cho POST tạo giao dịch.
- Auth user: Bearer (Phase 1). Admin P0: opaque Bearer credential từ env ánh xạ một `STAFF_ACTOR_ID`; chỉ role staff, không bypass khi thiếu config.

Workflow: sửa OpenAPI → PR cùng Nest DTO → client cập nhật.
