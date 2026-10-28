# Lịch tài chính — BE-P2-E04 / MOB-P2-E04

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `GET /api/v1/calendar`. Module: [15-calendar](../product/modules/15-calendar.md).

## Phạm vi phase 2

Một tháng lịch dân sự (`YYYY-MM`) theo `User.timezone`:

- Giao dịch đã ghi (`deletedAt` null, `occurredOn` trong tháng). Chuyển khoản một mục theo `transferGroupId`.
- Lần chạy định kỳ từ rule `active`, chiếu từ `nextExecutionDate` bằng `addInterval` (kẹp ngày 31). Không chiếu kỳ trước `nextExecutionDate`.
- Hạn hóa đơn (`dueOn` trong tháng), kể cả đã trả. `overdue` tính khi đọc.

Phase 3 (trả nợ, đáo hạn thẻ, đóng góp mục tiêu) chưa có trong API này.

## API

Bearer session, `Cache-Control: no-store`, tiền là string integer minor units.

`GET /api/v1/calendar?month=YYYY-MM` — `month` bắt buộc. Response: `month`, `timezone`, `today`, `days[]` (chỉ ngày có mục). Không log số tiền, tên hóa đơn, ghi chú.

## Mobile

Feature `lib/features/calendar/`. Màn `/me/calendar` từ Thiết lập tài chính (sau Hóa đơn). Lưới tháng, tuần bắt đầu thứ Hai; chấm theo loại; sheet chi tiết ngày.
