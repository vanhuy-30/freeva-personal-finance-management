# Sync — BE-P1-009

Hàng đợi mutation giao dịch. Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `POST /api/v1/sync`. Không CRDT, không pull cursor. CRUD [transactions](transactions.md) giữ nguyên, kể cả header `Idempotency-Key`.

## API

Bearer session, `Cache-Control: no-store`, owner lấy từ session. Không nhận hay trả `userId`. Không log body, ghi chú hay số tiền.

`schemaVersion` phải bằng `SchemaMeta.version` (hiện tại 1). Lệch trả `409 SYNC_SCHEMA_MISMATCH` và không ghi. Thiếu hàng `id = 1` trả `503 SYNC_UNAVAILABLE`. Body sai trả `400` trước mọi ghi.

Batch hợp lệ trả `200`. Tối đa 50 operation, `opId` UUID duy nhất trong request. Mỗi mục một transaction DB sẵn có, xử lý tuần tự. Mục sau vẫn chạy khi mục trước `conflict` hoặc `rejected`. Lỗi ngoài `TransactionError` ghi mục đó là `rejected` / `TRANSACTIONS_UNAVAILABLE` và bỏ các mục còn lại.

| Action | Body | Kết quả thành công |
|---|---|---|
| `create` | `CreateTransaction` | `applied`, hoặc `replayed` nếu `clientId` và payload đã chuẩn hóa khớp bản hiện tại |
| `update` | `UpdateTransaction` kèm `id` | `applied` |
| `delete` | `id` + `version` | `applied`, `transaction` null |

Create không dùng header `Idempotency-Key`. Khóa vẫn là `legs[0].clientId`, so sánh giống POST giao dịch.

`TRANSACTION_CONFLICT` thành `conflict` và không ghi đè. Kèm bundle server nếu đọc được. `review` chỉ `true` khi amount yêu cầu khác amount đang lưu, so bằng bigint. Version cũ nhưng cùng số tiền: `review` false. `VALIDATION_ERROR`, not found và account not found thành `rejected` với `details` rỗng.

## Gợi ý trùng

Chỉ khi create `applied`. Giao dịch active khác `clientId`, cùng owner, cùng ví, cùng `amountMinor`, cùng `occurredOn`, `createdAt` trong 10 phút tính tới bản vừa tạo. Tối đa 5, mỗi mục chỉ `{ id, clientId }`. Vẫn tạo, không drop. Replay không tính lại. Một leg của transfer khớp một giao dịch khác thì vẫn gợi ý.

## Ngoài phạm vi

Hàng đợi offline trên mobile là [MOB-P1-008](mobile-sync.md). Không sync ví/danh mục trong batch này, không last-write-wins, không đối soát.
