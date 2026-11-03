# Xuất CSV giao dịch — BE-P3-010 / MOB-P3-010

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `GET /api/v1/transactions/export.csv`. Phần mobile (`MOB-P3-010`) làm riêng.

## Chức năng

User xuất giao dịch (lọc theo khoảng ngày, ví, danh mục, nhãn, loại, tiền tệ, từ khóa như màn danh sách) ra file CSV mở thẳng bằng Excel, tiếng Việt đúng dấu. Đây là bản để đọc/phân tích, không phải bản sao lưu: sao lưu vẫn là JSON `GET /account/export`.

## Định dạng

- UTF-8 có BOM, RFC 4180 (ô có `,` `"` xuống dòng được bọc `"`, nháy kép nhân đôi), xuống dòng CRLF, dòng cuối có CRLF.
- Cột cố định (tiếng Anh, để `BE-P3-011` nhập lại được): `date,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id`.
- `amount`: số có dấu, dạng thập phân thuần tính bằng bigint từ minor units và `Currency.minorDigits` (`-125.50`, VND `-12500000`); không nhóm hàng nghìn, không theo locale. `currency` là cột riêng.
- Chặn công thức: ô văn bản (ví, danh mục, merchant, ghi chú, nhãn) bắt đầu bằng `=` `+` `-` `@`, tab hoặc CR được thêm `'` phía trước. Cột `amount` không bị đụng vì số âm là dữ liệu hợp lệ và do server sinh.
- Nhãn nối bằng `;`. Chuyển khoản là hai dòng (mỗi leg một dòng, cùng `date`).
- Sắp xếp cũ → mới, chỉ giao dịch chưa xóa.

## Giới hạn và bảo mật

- Tối đa 50 000 dòng (`CSV_EXPORT_MAX_ROWS`); vượt thì 400, app yêu cầu thu hẹp khoảng ngày.
- Bearer session, chỉ dữ liệu của owner; `Cache-Control: no-store`.
- Ghi audit `user.transactions_export` (chỉ userId) trong cùng transaction với lần đọc; ghi lỗi thì không trả file.
- Không log body, số tiền, ghi chú.

## Code

`transactions/domain/csv-export.ts` (thuần), `PrismaTransactionRepository.listForCsv` (dùng lại `listFilters`), `TransactionService.exportCsv`. Test: `csv-export.spec.ts`, `test/transactions-csv.integration-spec.ts`.
