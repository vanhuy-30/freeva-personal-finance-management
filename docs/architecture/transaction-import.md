# Nhập CSV từ app khác — BE-P3-011 / MOB-P3-011

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `POST /api/v1/transactions/import/preview`, `POST /api/v1/transactions/import`, `GET /api/v1/transactions/import/{id}`, `POST /api/v1/transactions/import/{id}/undo`. Phần mobile (`MOB-P3-011`) làm riêng.

## Chức năng

User chuyển giao dịch từ app khác (Money Lover, Sổ thu chi MISA) hoặc từ file Freeva (`BE-P3-010`) sang Freeva: xem trước từng dòng, map ví và danh mục, ghi cả lô, hoàn tác cả lô. Sao kê ngân hàng PDF/Excel vẫn là `BE-P5-E01`.

## Luồng (không lưu file tạm)

1. `preview`: client gửi `text` (nội dung CSV) và mapping; server không ghi gì, trả preset nhận diện, cột khớp, từng dòng `ready | duplicate | invalid` kèm mã lỗi, và `unmapped.wallets/categories` (tên chưa khớp).
2. User chọn ví/danh mục cho tên chưa khớp (`walletMap`, `categoryMap`, `defaultAccountId`) rồi gửi lại preview cho tới khi hài lòng.
3. `commit`: cùng body + `batchClientId`. Dòng `ready` ghi trong **một** transaction cơ sở dữ liệu, qua `createTransactionInTx` (đủ quy tắc: transfer hai chân cân, kind danh mục, ví đã lưu trữ). Dòng sai không chặn dòng khác.
4. `undo`: xóa mềm cả lô.

## Quy tắc

- **Loại:** chỉ `income`, `expense`, `transfer`. `adjustment`, `debt`, `refund` hoặc loại lạ → dòng `invalid` (`TYPE_UNSUPPORTED`). Không có cột loại thì lấy theo dấu số tiền.
- **Số tiền:** bigint từ văn bản theo `numberFormat` (`plain`, `dot_thousands` = `1.234,56`, `comma_thousands` = `1,234.56`), không float; thừa số lẻ khác 0 so với `minorDigits` → `AMOUNT_INVALID`. Tiền tệ lấy từ ví; cột `currency` lệch ví → `CURRENCY_MISMATCH`.
- **Ngày:** `iso`, `dmy`, `mdy`, có thể kèm giờ `HH:mm`.
- **Chuyển khoản:** hai dòng ngược dấu cùng ngày, giờ, số tiền, tiền tệ thành một transfer (như file export); dòng lẻ → `TRANSFER_UNPAIRED`. Khác tiền tệ chưa hỗ trợ.
- **Ví, danh mục:** khớp tên không phân biệt hoa thường và dấu; trùng tên mơ hồ hay không có → báo lỗi, người dùng map. Không tự tạo ví hay danh mục. Thu nhập được để trống danh mục, chi tiêu thì bắt buộc.
- **Trùng:** cùng ví, ngày, số tiền có dấu, loại và merchant/ghi chú chuẩn hóa với giao dịch đã có, hoặc `transaction_id` đã tồn tại. Mỗi giao dịch có sẵn chỉ khớp một dòng. Mặc định bỏ qua (`skipped_duplicate`); `includeDuplicates=true` mới ghi, và không bao giờ ghi đè.
- **Chặn công thức:** gỡ `'` đứng trước `= + - @` mà export thêm vào.
- **Nhãn** trong file chưa nhập (bỏ qua).

## Preset

`freeva` (header đúng cột export, tự nhận diện), `money_lover`, `misa`, `custom`. Header của Money Lover và MISA là danh sách alias ghi theo suy đoán (repo chưa có file mẫu thật): mọi cột ghi đè được bằng `mapping`, kiểu ngày/số bằng `dateFormat`/`numberFormat`.

## Dữ liệu

`ImportBatch` (đếm created/duplicate/invalid, `undoneAt`) và cột `Transaction.importBatchId` (SetNull). Migration `20261103300000_transaction_import_batch` additive. `clientId` giao dịch sinh tất định từ `batchClientId` + số dòng nên gửi lại cùng `batchClientId` trả `200` với lô đã lưu (`rows: null`), không nhân đôi. Có trong export/xoá tài khoản (`importBatches`).

## Hoàn tác

Xóa mềm mọi giao dịch của lô còn nguyên. Giao dịch đã sửa sau khi nhập (`version > 1`) hoặc gắn hoàn tiền / lịch trả góp đang chạy được bỏ qua và liệt kê trong `skipped` (`modified` | `linked`), không xóa im lặng. Gọi lại an toàn.

## Giới hạn và bảo mật

- Tối đa 2 000 dòng dữ liệu (`IMPORT_MAX_ROWS`, vì cả lô ghi trong một transaction), `text` ≤ 1 000 000 ký tự; route nhận body JSON tới 2 MB (`configure-http.ts`), vượt → `FILE_TOO_LARGE` / 413.
- Bearer session, chỉ dữ liệu của owner, `Cache-Control: no-store`.
- Audit `transaction_import.create` / `transaction_import.undo` chỉ gồm id. Không log nội dung file, số tiền, ghi chú.

## Code

`modules/transaction-import/`: `domain/csv-parse.ts`, `domain/import-format.ts`, `domain/transaction-import.ts` (thuần), repository Prisma, service, controller. Test: `domain/transaction-import.spec.ts`, `test/transactions-import.integration-spec.ts`.

**Tồn đọng:** `MOB-P3-011` chưa làm; chưa nhập Excel (`.xlsx`); header Money Lover/MISA chưa kiểm với file thật; chưa nhập nhãn; chuyển khoản khác tiền tệ chưa ghép; tối đa 2 000 dòng mỗi lần (file lớn phải chia nhỏ).
