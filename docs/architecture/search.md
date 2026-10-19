# Tìm kiếm — BE-P1-008

Module 19. Không endpoint mới và không migration. `search` nằm trên `GET /api/v1/transactions` đã có từ [transactions.md](transactions.md). UI không thuộc task này.

## Contract

Bearer session, owner từ session, `Cache-Control: no-store`. `search` tối đa 200 ký tự. Trim; chuỗi rỗng không lọc. Các lọc `status`, `accountId`, `categoryId`, `type`, `from`/`to` vẫn **AND** với `search`. Khoảng thời gian chỉ qua `from`/`to`.

Một leg khớp khi **một** vế sau đúng:

- Chuỗi đã fold là substring của ghi chú, tên danh mục gắn leg, tên ví, hoặc tên nhãn bất kỳ.
- Số tiền parse được bằng `abs(amountMinor)`.

Danh mục cha không kéo theo con. Ví và danh mục đã lưu trữ vẫn khớp. Bản xóa theo `status` (mặc định `active`). Vẫn trả leg, sort `occurredOn` giảm, `createdAt` giảm, `id` tăng. `total` đếm leg. List và count cùng snapshot Repeatable Read.

`%`, `_` và `\` trong query là ký tự literal. Không log query, ghi chú hay số tiền.

## Không dấu

Fold NFC rồi map 1-1, không phụ thuộc collation DB: `a/ă/â`, `e/ê`, `i`, `o/ô/ơ`, `u/ư`, `y`, `đ`, cả hoa lẫn thường, và `A–Z`. `cà phê` và `CA PHE` cùng ra `ca phe`.

## Số tiền

Bỏ space trong cả query. Query còn chữ (`cafe 50`) chỉ khớp chữ.

- `150000`, hoặc nhóm nghìn `150.000` / `150,000` (`^\d{1,3}([.,]\d{3})+$`), nếu vừa int64: so đúng `abs(amountMinor)`. `1.500` là 1500 minor, không phải 1.5. `12.501` là 12501 minor.
- Đúng một dấu `.` hoặc `,` mà phần lẻ không dài 3 (`12.50`, `12,5`, `12.05`): đơn vị chính × `10^minorDigits` của currency trên leg, phần lẻ được đệm, không làm tròn. Phần lẻ dài hơn `minorDigits` thì không khớp số tiền. `12.50` khớp USD `1250` và không khớp VND. `12.5001` không khớp USD.

Số vượt int64 không lọc theo tiền; vế chữ vẫn chạy.
