# Mục tiêu tiết kiệm — BE-P3-E01 / MOB-P3-E01

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/goals`. Module: [09-goals](../product/modules/09-goals.md). Phần mobile (`MOB-P3-E01`) làm riêng.

## Mô hình

- `Goal`: nhóm (`kind`), tên riêng, số đích, **số hiện tại** (lưu cứng), ngày đích, ví liên kết, mức đóng góp/tháng, `icon` + `colorToken` (token catalog, không hex), `archivedAt`, `version`. Tiền tệ = tiền tệ ví liên kết, không đổi sau khi tạo.
- `GoalEntry`: sổ đóng góp/rút (`contribute` | `withdraw`), `amountMinor > 0`, `clientId` idempotent, `transactionClientId` trỏ chân transfer nếu có.
- Nhóm có sẵn: `emergency`, `home`, `car`, `travel`, `education`, `wedding`, `retirement`, `custom` — `GET /goals/presets` trả icon/màu mặc định; user luôn đặt tên.

## Tiền đi đâu

Không có việc nào tự chạy. Chỉ khi user gọi:

| Thao tác | Giao dịch | Audit |
|---|---|---|
| `contribute` + `accountId` | một transfer cân hai chân ví nguồn → ví liên kết | không |
| `withdraw` + `accountId` | một transfer ví liên kết → ví đó | không |
| `contribute` / `withdraw` không `accountId` | không (tiền đã nằm trong ví liên kết) | không, chỉ có `GoalEntry` |
| `adjust` (sửa số đã có) | không | `goal.adjust` |
| tạo với `currentMinor > 0` | không | `goal.create` |

Transfer dùng `createTransactionInTx`, cùng một Prisma transaction với `GoalEntry` và `currentMinor`. Ví nguồn phải cùng tiền tệ và chưa lưu trữ. Rút không vượt `currentMinor` (`INSUFFICIENT_GOAL_BALANCE`, 422). Retry cùng `clientId` trả lại kết quả cũ; khác nội dung → 409. Id hai chân transfer sinh cố định từ `clientId`.

## Công thức

Số nguyên (`bigint`), không `double`.

- `percentBps = current * 10000 / target` (làm tròn xuống; 3333 = 33,33%).
- `monthsLeft`: số tháng lịch từ hôm nay (múi giờ hồ sơ) tới ngày đích, tháng đã bắt đầu tính tròn. Qua hạn → 0. Không ngày đích → `null`.
- `requiredPerMonthMinor = ceil((target - current) / monthsLeft)`; đã đủ → 0; không có tương lai để chia → `null`. Ví dụ: đích 120.000.000, hiện có 40.000.000, còn 10 tháng → 8.000.000.
- `incomeShareBps`: `requiredPerMonthMinor` trên thu nhập trung bình tháng (90 ngày gần nhất, cùng tiền tệ). Thiếu dữ liệu thì bỏ trường.
- `status`: `reached` (đủ) · `overdue` (qua hạn chưa đủ) · `active`.

## API

Bearer session, `Cache-Control: no-store`, tiền là string integer. `GET/POST /goals`, `GET/PATCH/DELETE /goals/{id}` (DELETE = lưu trữ, cần `version`), `GET /goals/presets`, `GET /goals/{id}/entries` (lịch sử góp, rút và sửa số, mới nhất trước, tối đa 200; `adjust` không có số tiền vì audit không lưu), `POST /goals/{id}/{contribute|withdraw|adjust}`. `POST /goals/preview` (`BE-P3-012`, câu 3 onboarding): trả `monthsLeft`, `requiredPerMonthMinor`, `incomeShareBps` cho một mục tiêu chưa tạo (chưa cần ví), không ghi gì; phần trăm tính trên thu nhập khai trên hồ sơ (`monthlyIncomeMinor`, cùng tiền tệ mặc định), không phải trung bình 90 ngày. Có trong `GET /account/export` (`goals`, `goalEntries`) và xoá theo user. Không log số tiền.
