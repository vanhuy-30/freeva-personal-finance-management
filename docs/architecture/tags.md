# Tags và merchant — BE-P1-012

Module 5 (nhãn) và mở rộng Module 4 (merchant trên thu/chi). Contract:
[OpenAPI](../../packages/api-contracts/openapi.yaml). Domain/repository không phụ thuộc
Prisma; adapter nằm trong infrastructure. UI thuộc `MOB-P1-011`.

## Nhãn

Bảng `Tag` đã có từ ADR 007. Task này chỉ thêm API CRUD theo owner. Mọi
`/api/v1/tags` yêu cầu Bearer session, giới hạn owner, trả `Cache-Control: no-store`.
Không nhận/trả `userId`, không log tên nhãn.

| Method / path | Hành vi |
|---|---|
| `POST /` | `{clientId,name}`; `201` mới / `200` replay cùng tên đã trim |
| `GET /` | `{items,page,pageSize,total}`; mặc định page 1, pageSize 50, tối đa 100 |
| `GET /{id}` | Chi tiết |
| `PATCH /{id}` | Đổi tên; bắt buộc `version` |
| `DELETE /{id}?version=` | Gỡ link rồi xóa; `204` |

Tên trim 1–100 ký tự, cho phép trùng. Unique chỉ `(userId, clientId)`. UUID
lowercase. ID thiếu hoặc khác owner trả `404`, không `403`. Replay `clientId` với
tên khác trả `409`. Không archive, không màu/icon, không `Idempotency-Key` header.

Xóa nhãn đang gắn giao dịch: trong cùng DB transaction Repeatable Read, gỡ
`TransactionTag`, tăng `version`/`updatedAt` mọi giao dịch liên quan (kể cả
soft-delete), rồi xóa `Tag`. Version giao dịch sát trần (`>= 2147483647`) trả
`409` và rollback. Gắn nhãn lên giao dịch vẫn qua `tagIds` của API giao dịch hiện có.

Mọi mutation gọi `touchFinancialOwner` trước khi đọc/ghi; retry serialization/
deadlock/unique tối đa ba lần.

Lỗi: `400 VALIDATION_ERROR`, `401` theo auth, `404 TAG_NOT_FOUND`, `409 TAG_CONFLICT`,
`503 TAGS_UNAVAILABLE`.

## Merchant

Migration additive `20261020120000_transaction_merchant` thêm `Transaction.merchant`
nullable. Không backfill.

- Optional trên thu và chi: string trim 1–200, hoặc `null`. Chuỗi rỗng sau trim là
  `400`. Create bỏ qua → `null`; PATCH bỏ qua giữ nguyên; `null` xóa.
- Cấm trên transfer: giá trị khác `null` là `400`. Response leg luôn có `merchant`
  (`null` với transfer).
- Replay idempotency và fingerprint canonical gồm `merchant`.
- Sync (`POST /api/v1/sync`) dùng lại DTO giao dịch nên merchant đi theo body.
- Export JSON gồm `merchant` trên mỗi giao dịch.
- Search khớp `merchant` (`DS-P2-005` / [search.md](search.md)). Top merchant trên cashflow: `BE-P2-E06` / [reports.md](reports.md).
- Log: path `merchant` trong Pino redact; HTTP logger không ghi body.

## Kiểm chứng và rollout

Xem [test README](../../backend/api/test/README.md#tags--merchant--be-p1-012).
Deploy migration trước API mới. Không deploy staging trong task này.

## Số giao dịch mỗi nhãn (DS-P2-003)

`GET /tags` thêm `transactionCount` cho từng dòng: số leg giao dịch chưa xoá có nhãn đó (chuyển ví có hai leg nên có thể tính hai). `GET /tags/:id` và POST không trả trường này.
