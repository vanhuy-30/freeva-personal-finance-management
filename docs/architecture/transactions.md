# Transactions — BE-P1-005

CRUD Module 4 theo ADR [006](adr/006-money-and-fx.md), [007](adr/007-core-data-model.md). Contract public: [OpenAPI](../../packages/api-contracts/openapi.yaml). Dùng schema hiện tại, không thêm migration. Domain/repository interface độc lập Nest HTTP và Prisma; adapter Prisma nằm trong infrastructure.

## API và payload

Tất cả `/api/v1/transactions` yêu cầu Bearer session người dùng, kiểm tra owner từ session và trả `Cache-Control: no-store`. Không nhận hoặc trả `userId`.

| Method / path | Hành vi |
|---|---|
| `POST /` | Tạo thu/chi hoặc cả cặp transfer; `201`, replay khớp `200` |
| `GET /` | Danh sách **leg** `{items,page,pageSize,total}`; transfer có thể chiếm hai dòng |
| `GET /{id}` | `{legs,fx}`; ID của bất kỳ leg nào trả toàn bộ cặp, kể cả đã xóa |
| `PATCH /{id}` | Bắt buộc version; sửa field gửi lên, giữ field bị bỏ qua; cả cặp tăng version |
| `DELETE /{id}?version=…` | Soft-delete toàn bộ cặp, `204`; không hard-delete |

POST bắt buộc header `Idempotency-Key` UUID trùng `legs[0].clientId` (không phân biệt hoa thường). Key sai/thiếu trả 400; retry giữ nguyên key và mọi clientId.

Payload transfer cùng currency:

```json
{
  "type": "transfer",
  "occurredOn": "2026-09-25",
  "legs": [
    { "clientId": "11111111-1111-4111-8111-111111111111", "accountId": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", "currencyCode": "VND", "amountMinor": "-150000" },
    { "clientId": "22222222-2222-4222-8222-222222222222", "accountId": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", "currencyCode": "VND", "amountMinor": "150000" }
  ]
}
```

- Thu/chi có một leg; thu dương, chi âm. Transfer có đúng hai leg theo thứ tự **nguồn âm, đích dương**, khác ví và khác clientId. Từ chối số 0, self-transfer, lệch tổng và sai dấu.
- Tiền JSON là string integer trong signed int64, tối đa 20 ký tự; tính bằng bigint. Số dư derived của ví vẫn có thể vượt int64.
- Currency từng leg phải khớp ví. Ví phải thuộc owner và đang hoạt động khi tạo/sửa/khôi phục. Cho phép xóa giao dịch của ví đã lưu trữ; không kiểm tra đủ số dư, vì ví được có số dư âm và thẻ credit biểu diễn nợ.
- `occurredOn` là ngày lịch `YYYY-MM-DD` hợp lệ, năm 0001–9999; không chuyển ngày theo UTC. Hai leg luôn cùng ngày, type, group, quote, version và trạng thái xóa.
- `categoryId` bắt buộc, khác null với chi theo UC-EXP-01/02; thu optional/null, transfer phải null/bỏ qua. Danh mục thuộc owner và chưa lưu trữ. `notes` optional/null, tối đa 2000 ký tự. `tagIds` mặc định `[]`, tối đa 20 UUID thuộc owner; PATCH thay toàn bộ danh sách nhãn. Với transfer, notes/tags áp dụng cho cả cặp.
- PATCH `legs` thay đầy đủ cả cặp (hoặc một leg thu/chi); giữ nguyên clientId và thứ tự. Cho phép sửa tiền/đổi ví, nhưng `type` và clientId bất biến. `fx`, `notes` nhận null; `categoryId` chỉ nhận null khi không phải chi; field khác không nhận null.
- PATCH `{version,deleted:false}` khôi phục cả cặp. Giao dịch đã xóa phải khôi phục trước hoặc cùng request sửa. Xóa lặp lại với version hiện tại giữ timestamp xóa cũ, vẫn tăng version. Version input 1–2147483646; version cuối 2147483647.
- Sao chép dùng POST với clientId mới; không có endpoint copy riêng. Mỗi leg trả `transferGroupId`/`fxQuoteId` nullable, ngày, timestamps, version và tagIds; chi tiết `{legs,fx}` trả rate và thời điểm đã lưu.

## FX và acceptance contract

Transfer khác currency bắt buộc `fx: {rate,quotedAt}`. Rate string dương, tối đa 10 chữ số phần nguyên + 8 thập phân, phù hợp `Decimal(18,8)`; timestamp ISO 8601 bắt buộc timezone. Cùng currency và thu/chi không nhận FX.

```text
destinationMinor = abs(sourceMinor) × rate × 10^destinationMinorDigits / 10^sourceMinorDigits
```

Tính bằng phân số bigint; **từ chối kết quả có phần lẻ minor unit**, không làm tròn ngầm. Từ chối amount đích không khớp hoặc vượt int64. Rate chuẩn hóa 8 chữ số thập phân. Lưu một FxQuote `source=manual`, cả hai leg cùng tham chiếu. Sửa rate/thời điểm/hướng tiền tệ tạo quote mới, không mutate quote cũ; sửa ghi chú tái sử dụng quote. Quote cũ được giữ lại, chưa có API quản lý/xóa quote.

[Fixture QA-P0-002](transfer-balance-test-cases.md) chạy trực tiếp evaluator domain production; thêm zero/self-transfer/ngày/trạng thái xóa, decimal exact và fractional FX. Transaction boundary và rollback kiểm tra bằng PostgreSQL thật.

## Atomicity, retry và chống trùng

- Mỗi mutation chạy trong một DB transaction Repeatable Read: khóa cả cặp theo thứ tự ID, kiểm tra version, khóa ví cũ/mới theo thứ tự ID, kiểm tra owner/currency/archived, rồi ghi quote, hai leg và tag links. Bất kỳ lỗi nào rollback toàn bộ.
- Writer **update updatedAt của các ví liên quan**, không tăng version ví vì không thay field cấu hình. Chỉ khóa hàng không đủ: account writer có snapshot cũ có thể chưa thấy giao dịch mới. Update này buộc writer `BE-P1-004` retry snapshot, rồi khóa đổi type/currency khi đã có lịch sử. Client đọc ví lại sẽ thấy số dư derived mới.
- Retry tối đa 3 lần sau serialization/deadlock; create retry thêm unique collision. Hai request sửa cùng version chỉ một request thắng, kể cả dùng ID hai leg khác nhau. List/count chạy cùng snapshot; phân trang giữa các request không giữ snapshot dài hạn.
- Unique `(userId,clientId)` từng leg; Idempotency-Key ánh xạ clientId leg đầu, không lưu key riêng. Replay so sánh payload đã chuẩn hóa với **giá trị hiện tại** toàn bộ giao dịch, không lưu snapshot request gốc: bigint, UUID lowercase, defaults null/[], tags sắp xếp, rate chuẩn hóa và timestamp UTC. Khớp trả `200` với version/trạng thái hiện tại; khác, thiếu một clientId, hoặc đổi partner trả `409`. Replay không tự khôi phục. Sau khi sửa payload, retry POST cũ có thể conflict.
- Writer categories/tags tương lai cần phối hợp transaction/locking khi archive, chuyển hoặc xóa reference; CRUD categories thuộc `BE-P1-006`.

## List, lỗi và privacy

Page mặc định 1, pageSize 50, tối đa 100. `status=active` mặc định, hoặc `deleted`/`all`. Lọc `accountId`, `categoryId`, `type`, `from`/`to` inclusive; `search` tìm notes không phân biệt hoa thường, tối đa 200 ký tự. Sort occurredOn giảm, createdAt giảm, id tăng. `total` đếm leg, không đếm transfer group; báo cáo thu/chi phải lọc type, không tính transfer là thu/chi.

`400 VALIDATION_ERROR`, `401` theo auth service, `404 TRANSACTION_NOT_FOUND`/`ACCOUNT_NOT_FOUND` cho cả ID không tồn tại và khác owner, `409 TRANSACTION_CONFLICT`, `503 TRANSACTIONS_UNAVAILABLE`. Lỗi không phản chiếu input hoặc exception Prisma. HTTP logger không ghi body/query/header, ghi chú, số tiền hoặc bearer token.

Chưa triển khai sync queue, báo cáo, đối soát, receipt hoặc batch edit. Không deploy staging trong task này. Lệnh kiểm tra và coverage: [test README](../../backend/api/test/README.md#transactions--be-p1-005).
