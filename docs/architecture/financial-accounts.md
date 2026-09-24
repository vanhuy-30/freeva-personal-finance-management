# Financial accounts — BE-P1-004

CRUD backend cho Module 3, theo ADR [006](adr/006-money-and-fx.md), [007](adr/007-core-data-model.md). Contract public: [OpenAPI](../../packages/api-contracts/openapi.yaml). Không có migration mới; dùng schema hiện tại.

## API

Tất cả endpoint `/api/v1/financial-accounts` yêu cầu Bearer session người dùng, trả `Cache-Control: no-store`. Không nhận owner từ client và không trả `userId`.

| Method / path | Hành vi |
|---|---|
| `POST /` | Tạo `cash`, `bank`, `ewallet`, `credit`; `201` hoặc `200` khi replay cùng dữ liệu |
| `GET /` | `{items,page,pageSize,total}`; mặc định page 1 / pageSize 50, tối đa 100; `status=active` mặc định, hoặc `archived`, `all` |
| `GET /{id}` | Chi tiết và số dư, kể cả ví đã lưu trữ |
| `PATCH /{id}` | Sửa từng trường, bắt buộc version hiện tại; `archived: false` khôi phục, `true` lưu trữ |
| `DELETE /{id}?version=…` | Lưu trữ, trả `204`; không hard-delete hoặc thay đổi giao dịch |

List sắp xếp `sortOrder`, `createdAt`, `id` tăng dần. Timestamp ISO 8601; tiền là string integer. Currency lấy từ catalog hiện có (`GET /api/v1/profile/options`), không tự thêm mã tiền tệ từ request.

Tên trim, 1–100 ký tự; `sortOrder` 0–2147483647, mặc định 0. Số tiền đầu vào có tối đa 20 ký tự và nằm trong signed int64; không nhận JSON number, số thập phân hoặc số mũ. Số dư ban đầu được âm. Các trường thẻ nullable, chỉ được có giá trị với `credit`: hạn mức không âm, ngày chốt/thanh toán 1–28. Bỏ qua trường trong PATCH nghĩa là giữ giá trị; chỉ trường thẻ nhận null.

## Số dư, lịch sử và ghi đồng thời

- `balanceMinor = initialBalanceMinor + SUM(amountMinor)` của giao dịch cùng owner/ví có `deletedAt = null`. Bao gồm cả transfer; không cached balance, không quy đổi FX hoặc tạo giao dịch số dư ban đầu.
- `SUM(bigint)` PostgreSQL đọc qua text rồi chuyển thành JS bigint; số dư derived có thể vượt int64. Các query đọc ví, giao dịch và total dùng cùng snapshot Repeatable Read.
- Cho sửa số dư ban đầu để đính chính; không sửa giao dịch cũ. Có bất kỳ giao dịch nào, kể cả đã soft-delete, thì khóa đổi `type` và `currencyCode`.
- Đổi khỏi `credit` khi chưa có giao dịch sẽ xóa cấu hình thẻ trong cùng transaction. Nếu request đồng thời gửi cấu hình thẻ khác null thì trả validation error.
- Update/archive/restore khóa hàng theo owner và kiểm tra version trong transaction. Mỗi write thành công tăng version, kể cả no-op; lưu trữ lại giữ nguyên archivedAt. Version đầu vào 1–2147483646; version cuối có thể đạt 2147483647.
- Retry transaction tối đa 3 lần sau serialization/deadlock; create retry khi đụng unique. Hai request update cùng version chỉ một request thành công, request còn lại nhận conflict.
- `clientId` UUID bắt buộc, unique theo owner. Retry POST so sánh các trường tạo sau chuẩn hóa với **giá trị hiện tại**: tên đã trim, UUID lowercase, tiền bigint, defaults 0/null. Nếu khớp, trả ví hiện có cùng số dư/version/trạng thái hiện tại; nếu đã sửa khác payload tạo thì trả `409`. Không lưu snapshot payload ban đầu, không tự khôi phục ví khi replay.
- `BE-P1-005` khi thêm writer giao dịch phải phối hợp khóa ví và kiểm tra owner/currency/trạng thái trong transaction; task này chưa cung cấp API ghi giao dịch.

## Lỗi và quyền riêng tư

`400 VALIDATION_ERROR`, `401 SESSION_INVALID`, `404 ACCOUNT_NOT_FOUND` cho cả ID không tồn tại lẫn khác owner, `409 ACCOUNT_CONFLICT`, `503 ACCOUNTS_UNAVAILABLE` cho lỗi hạ tầng. Lỗi auth giữ mã của auth service. Envelope không phản chiếu input; không log exception Prisma. Serializer HTTP không ghi query/header/body; không log tên ví, số tiền hoặc token.

Module có controller/service, repository abstract trong domain, adapter Prisma trong infrastructure. Không thêm UI, báo cáo/net worth, đối soát, sync queue hoặc hard-delete trong task này.

Kiểm thử và lệnh chạy: [backend test README](../../backend/api/test/README.md#financial-accounts--be-p1-004).
