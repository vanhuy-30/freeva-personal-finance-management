# Báo cáo — BE-P1-007 / BE-P2-E06 / BE-P2-E08

Module 14. Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml). Không migration. Domain và repository interface không phụ thuộc Prisma; adapter infrastructure là nơi truy cập DB.

Ngoài phạm vi: ngân sách (`BE-P2-E02`), tài sản ròng theo thời gian từng ngày, CSV, lời AI (`BE-P5-E04`). UI nằm ở [mobile-reports.md](mobile-reports.md).

## API

Các GET `/api/v1/reports/*` yêu cầu Bearer session, lấy owner từ session và trả `Cache-Control: no-store`. Không nhận hoặc trả `userId`, tên ví, tên danh mục. Tiền là string integer, có thể vượt int64. Không quy đổi FX và không cộng khác loại tiền.

| Method / path | Hành vi |
|---|---|
| `GET /cashflow` | Thu, chi, dòng tiền của một kỳ, theo danh mục lá và theo ví; kèm so kỳ liền trước, savings rate và top merchant |
| `GET /month-review` | Bản soát một tháng tài chính: thu, chi, tiết kiệm, savings rate, top 3 danh mục chi (`BE-P2-E08`) |
| `GET /trend` | Chuỗi cột chi/thu cho biểu đồ xu hướng nhóm F, một lần gọi (`DS-P2-003`) |
| `GET /series` | Chuỗi thu/chi theo cửa sổ 7 ngày, 30 ngày, 3/6/12 tháng tài chính hoặc toàn bộ năm (`BE-P2-E06`) |
| `GET /net-worth` | Tài sản, nợ và ròng hiện tại; không lọc kỳ |

`period` bắt buộc trên cashflow: `week`, `month`, `year` hoặc `range`.

- Tuần: thứ Hai đến Chủ nhật, tính trên ngày lịch. `on` là ngày mốc; bỏ qua thì lấy hôm nay theo `User.timezone`.
- Tháng: kỳ tài chính chứa `on`, theo `fiscalMonthStartDay` (1–28). Ví dụ ngày bắt đầu 15 và `on=2026-10-08` cho `2026-09-15` … `2026-10-14`.
- Năm: năm dương lịch chứa `on`, `01-01` đến `12-31`, không theo `fiscalMonthStartDay`.
- Khoảng: `from` và `to` inclusive, `from <= to`, cách nhau tối đa 3660 ngày. `on` bị cấm. `from`/`to` bị cấm với tuần, tháng và năm.

Ngày không hợp lệ, năm ngoài 0001–9999, hoặc kỳ tràn khỏi miền đó trả `400`. Không dịch ngày qua UTC.

`400 VALIDATION_ERROR`, `401` theo auth service, `503 REPORTS_UNAVAILABLE`. Envelope không phản chiếu input. HTTP logger không ghi query, header, body; không log số tiền hay tên merchant.

## Công thức

Mỗi lần đọc chạy trong một transaction Repeatable Read: hồ sơ (timezone, ngày bắt đầu tháng) và các tổng lấy cùng snapshot. `SUM(bigint)::text` rồi chuyển thành bigint, cùng cách số dư ví. Chỉ giao dịch `deletedAt` null. `occurredOn` so sánh như `date`.

**Cashflow, mỗi currency có thu hoặc chi trong kỳ:**

- `incomeMinor` = tổng `type=income` (dương)
- `expenseMinor` = tổng `type=expense` (âm)
- `netMinor` = income + expense (= tiết kiệm của kỳ)
- `savingsRateBps` = `netMinor * 10000 / incomeMinor` khi thu `> 0`, ngược lại `null` (3933 = 39,33%). Chia nguyên, kẹp safe integer.
- Transfer không vào ba số này và không vào `byCategory`

`byCategory` nhóm theo `categoryId` của giao dịch, không gộp lên cha. Trả `parentId` để client tự gộp. `categoryId` null là thu chưa phân loại. Danh mục đã ẩn vẫn tính nếu còn giao dịch trong kỳ. Dòng cả thu lẫn chi bằng 0 bị bỏ. `transactionCount` là số giao dịch thu/chi chưa xoá trong dòng đó.

`byAccount` gồm mọi ví đang hoạt động, cộng ví đã lưu trữ nếu có giao dịch trong kỳ. Mỗi ví có `incomeMinor`, `expenseMinor`, `transferMinor` và `netMinor` bằng tổng ba số. Transfer làm đổi số dư ví nhưng không phải thu hay chi. Không cộng `byAccount` vào `totals`.

**So kỳ liền trước** (`comparison`): cùng loại kỳ — tuần trước, tháng tài chính trước, năm dương lịch trước; khoảng tuỳ chọn lùi đúng số ngày inclusive của khoảng đang xem. Kỳ trước tràn khỏi 0001–9999 → `400`. `totals` của kỳ trước cùng shape (kèm `savingsRateBps`). `expenseDeltaBps` mỗi currency có ở một trong hai kỳ: `(|chi kỳ này| − |chi kỳ trước|) * 10000 / |chi kỳ trước|`; dương = chi nhiều hơn; `null` khi kỳ trước không có chi.

**Top merchant** (`topMerchants`): tối đa 10 cửa hàng mỗi currency trong kỳ đang xem. Chỉ `expense` và `merchant` khác null; nhóm đúng chuỗi đã lưu (không gộp hoa/thường). Xếp theo `|expense|` giảm rồi tên. Mỗi dòng: `currency`, `merchant`, `expenseMinor`, `transactionCount`.

**Soát tháng** (`GET /month-review?on=`): tháng tài chính chứa `on` (mặc định hôm nay theo timezone hồ sơ). Chiếu từ cùng công thức cashflow tháng: mỗi currency có `incomeMinor`, `expenseMinor`, `savingsMinor` (= `netMinor`), `savingsRateBps`. `topCategories` tối đa 3 lá chi theo `|expense|` giảm, hòa thì `categoryId` (null sau cùng); không gộp cha, không trả tên. Không gọi kỳ trước, merchant hay ví. Không có lời AI.

**Xu hướng** (`GET /trend?period=week|month|year&on=`): các cột xếp cũ → mới, cột cuối là kỳ chứa `on`. Tuần 8 cột (thứ Hai–Chủ nhật), tháng 6 cột theo `fiscalMonthStartDay`, năm tối đa 5 năm dương lịch; năm trước giao dịch đầu tiên bị bỏ, năm hiện tại luôn có. Mỗi cột có `totals` theo currency (thu, chi như cashflow, không có transfer); currency không phát sinh thì vắng. Một câu SQL cho cả chuỗi, cùng snapshot với hồ sơ. Lịch sử dừng ở năm 100 (giới hạn `Date.UTC`).

**Chuỗi** (`GET /series?window=7d|30d|3m|6m|1y|all&on=`): cột cũ → mới, cột cuối chứa `on` (mặc định hôm nay theo timezone hồ sơ). `7d` / `30d` là từng ngày lịch. `3m` / `6m` / `1y` là 3 / 6 / 12 tháng tài chính. `all` là mỗi năm dương lịch từ năm giao dịch thu/chi đầu tiên đến năm của `on`; năm hiện tại luôn có; dừng ở năm 100. Cùng SQL dạng `VALUES` như trend.

**Net worth hiện tại, mỗi currency có ít nhất một ví đang dùng. Ví đã ẩn (lưu trữ) không tính** (`DS-P2-003`, khớp "Tổng số dư · N ví" ở Tổng quan và Ví):

- Số dư ví = `initialBalanceMinor` + tổng giao dịch chưa xóa, gồm transfer
- `assetsMinor` = tổng số dư `cash`, `bank`, `ewallet`. Âm là thấu chi, vẫn ở tài sản
- `liabilitiesMinor` = tổng số dư `credit`. Âm là nợ; dương là trả dư và vẫn ở nợ
- `netWorthMinor` = assets + liabilities

## Kiểm thử

Lệnh và kết quả: [backend test README](../../backend/api/test/README.md#reports--be-p1-007--be-p2-e06--be-p2-e08). Không deploy staging.
