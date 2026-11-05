# Cho mượn và đi mượn — BE-P3-007 / MOB-P3-007

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/personal-debts`. Module: [10-loans](../product/modules/10-loans.md). Không lãi suất; vay có lãi, lịch trả và gốc/lãi là [loans.md](loans.md) (`BE-P3-E02`). Phần mobile: [mobile-debts-loans.md](mobile-debts-loans.md).

## Mô hình

- `PersonalDebt`: hướng (`lent` cho mượn → phải thu, `borrowed` đi mượn → phải trả), tên người (≤ 80), tiền tệ (lấy từ ví), **gốc** (`principalMinor`), **còn lại** (`outstandingMinor`, lưu cứng), ví, ngày, hạn tuỳ chọn (không trước ngày ghi), ghi chú ≤ 500, `archivedAt`, `version`.
- `PersonalDebtPayment`: một lần thu hoặc trả, `amountMinor`, ví, `clientId` idempotent, `transactionClientId` của chân giao dịch.

## Tiền đi đâu

Mỗi lần tiền di chuyển là **một** giao dịch `debt` một chân (`TransactionType.debt`, migration `20261102500000_personal_debts`, additive; deploy trước API), cùng commit với số còn lại. Không phải thu hay chi: không vào báo cáo thu/chi, ngân sách, tỷ lệ tiết kiệm, nhưng có trong số dư và lịch sử ví, export, sổ cái. Báo cáo theo ví có thêm `debtMinor`, `summary.totals[].debtMinor` của `/transactions` tách riêng.

| Thao tác | Chân giao dịch | Audit |
|---|---|---|
| tạo, cho mượn | âm (tiền ra ví) | `personal_debt.create` |
| tạo, đi mượn | dương (tiền vào ví) | `personal_debt.create` |
| thu lại một khoản đã cho mượn | dương | không |
| trả một khoản đã đi mượn | âm | không |

- Trả hoặc thu một phần nhiều lần; trả đủ số còn lại là tất toán (`status = settled`). Quá số còn lại → `DEBT_OVERPAYMENT` (422), không cắt ngầm.
- Ví trả phải cùng tiền tệ với khoản nợ; mặc định là ví của khoản nợ.
- Retry cùng `clientId` trả kết quả cũ (200); khác nội dung → 409. Id chân giao dịch sinh cố định từ `clientId`.
- `PATCH`/`DELETE /transactions/{id}` trên chân `debt` → 400: sửa hoặc xóa sẽ lệch số còn lại.
- Lưu trữ (`DELETE /personal-debts/{id}`) chỉ khi đã tất toán, nếu không `DEBT_CONFLICT` (409); lưu trữ khoản đang mở sẽ làm nó biến mất khỏi tài sản ròng trong khi ví đã đổi.

## Tài sản ròng

`GET /reports/net-worth`: tổng còn lại của khoản **đang mở** (chưa lưu trữ) cộng vào `assetsMinor` với `lent` và trừ vào `liabilitiesMinor` (số âm) với `borrowed`, theo tiền tệ. Cho mượn 3.000.000 từ ví 10.000.000: ví 7.000.000 + phải thu 3.000.000, tài sản ròng giữ 10.000.000.

## Nhắc

Loại thông báo `debt` (có sẵn, nay mở khóa; công tắc `debtEnabled`, mặc định tắt). Khoản còn lại có `dueDate`: nhắc một lần khi còn ≤ 3 ngày (`debt_due`) và một lần khi quá hạn (`debt_overdue`), dedupe theo `debt|due|{id}|{dueDate}` hoặc `debt|overdue|…`. Params và push chỉ có hướng, số ngày, ngày hạn; không tên người, không số tiền. Không tự ghi tiền.

## API

Bearer session, `Cache-Control: no-store`, tiền là string integer. `GET/POST /personal-debts`, `GET/PATCH/DELETE /personal-debts/{id}` (cần `version`), `GET /personal-debts/summary` (Ai nợ mình `owedToMe` / Mình nợ ai `iOwe` kèm tổng phải thu, phải trả theo tiền tệ), `GET/POST /personal-debts/{id}/payments`. `status`: `open` · `overdue` (quá `dueDate`, còn nợ) · `settled`. Có trong `GET /account/export` (`personalDebts`, `personalDebtPayments`) và xoá theo user. Không log số tiền hay tên người (`debtMinor` nằm trong danh sách redact).
