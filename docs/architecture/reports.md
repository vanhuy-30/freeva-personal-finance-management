# Báo cáo — BE-P1-007

Module 14, bản đọc hiện tại. Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml). Không migration. Domain và repository interface không phụ thuộc Prisma; adapter infrastructure là nơi truy cập DB.

Ngoài phạm vi: so sánh kỳ, ngân sách, chi lớn, tài sản ròng theo thời gian, CSV, search (`BE-P1-008`) và UI (`MOB-P1-006`).

## API

Hai GET `/api/v1/reports/*` yêu cầu Bearer session, lấy owner từ session và trả `Cache-Control: no-store`. Không nhận hoặc trả `userId`, tên ví, tên danh mục. Tiền là string integer, có thể vượt int64. Không quy đổi FX và không cộng khác loại tiền.

| Method / path | Hành vi |
|---|---|
| `GET /cashflow` | Thu, chi, dòng tiền của một kỳ, theo danh mục lá và theo ví |
| `GET /net-worth` | Tài sản, nợ và ròng hiện tại; không lọc kỳ |

`period` bắt buộc: `week`, `month` hoặc `range`.

- Tuần: thứ Hai đến Chủ nhật, tính trên ngày lịch. `on` là ngày mốc; bỏ qua thì lấy hôm nay theo `User.timezone`.
- Tháng: kỳ tài chính chứa `on`, theo `fiscalMonthStartDay` (1–28). Ví dụ ngày bắt đầu 15 và `on=2026-10-08` cho `2026-09-15` … `2026-10-14`.
- Khoảng: `from` và `to` inclusive, `from <= to`, cách nhau tối đa 3660 ngày. `on` bị cấm. `from`/`to` bị cấm với tuần và tháng.

Ngày không hợp lệ, năm ngoài 0001–9999, hoặc kỳ tràn khỏi miền đó trả `400`. Không dịch ngày qua UTC.

`400 VALIDATION_ERROR`, `401` theo auth service, `503 REPORTS_UNAVAILABLE`. Envelope không phản chiếu input. HTTP logger không ghi query, header, body; không log số tiền.

## Công thức

Mỗi lần đọc chạy trong một transaction Repeatable Read: hồ sơ (timezone, ngày bắt đầu tháng) và các tổng lấy cùng snapshot. `SUM(bigint)::text` rồi chuyển thành bigint, cùng cách số dư ví. Chỉ giao dịch `deletedAt` null. `occurredOn` so sánh như `date`.

**Cashflow, mỗi currency có thu hoặc chi trong kỳ:**

- `incomeMinor` = tổng `type=income` (dương)
- `expenseMinor` = tổng `type=expense` (âm)
- `netMinor` = income + expense
- Transfer không vào ba số này và không vào `byCategory`

`byCategory` nhóm theo `categoryId` của giao dịch, không gộp lên cha. Trả `parentId` để client tự gộp. `categoryId` null là thu chưa phân loại. Danh mục đã ẩn vẫn tính nếu còn giao dịch trong kỳ. Dòng cả thu lẫn chi bằng 0 bị bỏ.

`byAccount` gồm mọi ví đang hoạt động, cộng ví đã lưu trữ nếu có giao dịch trong kỳ. Mỗi ví có `incomeMinor`, `expenseMinor`, `transferMinor` và `netMinor` bằng tổng ba số. Transfer làm đổi số dư ví nhưng không phải thu hay chi. Không cộng `byAccount` vào `totals`.

**Net worth hiện tại, mỗi currency có ít nhất một ví, kể cả ví đã lưu trữ:**

- Số dư ví = `initialBalanceMinor` + tổng giao dịch chưa xóa, gồm transfer
- `assetsMinor` = tổng số dư `cash`, `bank`, `ewallet`. Âm là thấu chi, vẫn ở tài sản
- `liabilitiesMinor` = tổng số dư `credit`. Âm là nợ; dương là trả dư và vẫn ở nợ
- `netWorthMinor` = assets + liabilities

## Kiểm thử

Lệnh và kết quả: [backend test README](../../backend/api/test/README.md#reports--be-p1-007). Không deploy staging.
