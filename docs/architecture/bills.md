# Hóa đơn — gộp vào định kỳ (BE-P3-001)

Hóa đơn không còn là bảng riêng. Một `RecurringRule` có hai chế độ ([recurring.md](recurring.md)); hóa đơn là chế độ `remind`. Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/recurring-transactions`. Module: [08-bills](../product/modules/08-bills.md).

## Mô hình

- `mode = remind`: chỉ nhắc, **không bao giờ tự ghi giao dịch**. Bắt buộc `type = expense` và `name`; ví và danh mục tùy chọn (dùng làm mặc định khi xác nhận). Số tiền âm như mọi rule; `amountKind` = `fixed` | `estimated`; `remindDaysBefore` 0–30 (mặc định 3).
- Hóa đơn một lần = rule không lặp (`repeat: false` → `endDate = startDate`). Xác nhận xong thì `active = false`.
- Hạn tiếp theo là `nextExecutionDate`. Quá hạn **tính khi đọc** (`overdue`): đang `active` và hạn trước hôm nay theo `User.timezone`. Quá hạn không tự ghi.
- Mỗi lần "Đã trả" ghi một `RecurringOccurrence` (`unique(ruleId, occurredOn)`) trỏ tới `clientId` của giao dịch.

## Xác nhận đã trả

`POST /api/v1/recurring-transactions/{id}/confirm` — `version`, `occurredOn` (hạn đang xác nhận, bắt buộc), rồi một trong hai:

- `transactionId`: trỏ tới khoản chi có sẵn (không tạo mới). Một khoản chi chỉ trả một hạn.
- hoặc để trống: tạo một expense (`accountId`/`categoryId` lấy từ body hoặc rule; `amountMinor` dương nếu hóa đơn ước tính; `paidOn` mặc định hôm nay).

Gọi lại cùng `occurredOn` (retry, sync, bấm hai lần) trả 200 `replayed: true` với giao dịch cũ — không ghi hai giao dịch. Sai hạn hoặc rule `auto` → lỗi. Chưa có thao tác hoàn tác (`unpay`).

## Nhắc

Loại `recurring`: `bill_due` (từ `remindDaysBefore` ngày trước hạn) và `bill_overdue` (một lần khi quá hạn), dedupe theo rule + hạn. Dùng công tắc `recurringEnabled`, giờ yên và push FCM như các thông báo khác. Params không chứa số tiền.

## Chuyển từ `Bill`

Migration `20261102200000_recurring_remind_mode`: mỗi `Bill` thành rule `remind` một lần với **cùng `id` và `clientId`**, số tiền đổi dấu; hóa đơn đã trả giữ liên kết giao dịch qua một occurrence. Hóa đơn chưa trả gắn rule `auto` bị bỏ (rule đó đã tự ghi). Bảng `Bill` còn nguyên để quay lui, sẽ xóa ở bản sau.

`/api/v1/bills` (mọi method, mọi đường dẫn con) trả **410** `BILL_GONE`. Lịch ([calendar.md](calendar.md)) chỉ đọc lại dữ liệu rule. Export có hóa đơn trong `recurringRules` (`mode: remind`); `bills` là bảng cũ.
