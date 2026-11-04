# Nhóm L — Định kỳ và hóa đơn

Trạng thái: **chốt thiết kế 2026-11-03**, **đã code 2026-11-04** ([mobile](../../architecture/mobile-recurring-bills.md)). Task: `MOB-P3-001` (API `BE-P3-001` xong). Thay màn "Định kỳ" và "Hóa đơn" đang chạy (hàng "P2 · Đã có trong app" trên trang 05).
Canvas: trang **07 · Phase 3**, hàng L. Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Hóa đơn không còn là màn riêng: một khoản định kỳ có **hai cách ghi**:
  - **Ghi tự động** (`mode: auto`): đến ngày tự ghi. Dòng phụ "Hợp với lương, tiền nhà".
  - **Hỏi trước khi ghi** (`mode: remind`): đến hạn hỏi, xác nhận mới ghi. Dòng phụ "Hợp với tiền điện, nước".
- Tên hai cách ghi dùng được cho cả Chi, Thu, Chuyển (không dùng "Nhắc tôi trả").
- Chữ không tả Freeva đang làm gì ("Freeva hỏi, bạn…"); dùng ví dụ thực tế.
- Khoản Ghi tự động không có "Nhắc trước" và "Số tiền mỗi kỳ có thể khác".

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Định kỳ và hóa đơn | Quay lại · tiêu đề · +. Thẻ "Cần trả 7.330.000 · 3 hóa đơn chưa trả · xem trên lịch". Nhóm **CẦN TRẢ**: icon, tên + tag (Quá hạn / Còn N ngày), "Hạn 05/11 · khoảng 850.000", nút đen "Đã trả". Nhóm **GHI TỰ ĐỘNG**: tên, "Ngày 5 hằng tháng", số tiền | Khoản tạm dừng: tag xám "Tạm dừng", số tiền màu muted. Một lần: "Hạn 15/11 · một lần" |
| 2 | Thêm định kỳ · Hỏi trước khi ghi | Đóng · "Thêm định kỳ". Công tắc **Chi · Thu · Chuyển**. Nhóm radio hai dòng (cách ghi). Tên, Số tiền, dòng công tắc "Số tiền mỗi kỳ có thể khác · Nhập số thật khi xác nhận". Lặp lại + Hạn đầu tiên, chip Nhắc trước (Đúng ngày / 1 / 3 / 7 ngày), Trả từ ví, Danh mục. "Lưu" | Lặp lại có "Một lần" cho hóa đơn không lặp |
| 3 | Sửa định kỳ · Ghi tự động | Tiêu đề là tên khoản. Như 2 nhưng không có công tắc số tiền và Nhắc trước; "Lần tới" thay "Hạn đầu tiên". Dòng công tắc **Tạm dừng** · "Không ghi, không nhắc cho đến khi bật lại". "Lưu" · nút chữ đỏ "Xoá định kỳ" | Chạm dòng Ghi tự động ở 1 mở màn này |
| 4 | Xác nhận đã trả (sheet trên 1) | Icon, "Đã trả tiền điện?", "Hạn 05/11 · khoảng 850.000". "Số tiền thật" lớn. Trả từ ví, Ngày trả (mỗi ô một dòng). "Xác nhận đã trả" · liên kết "Đã ghi khoản chi này rồi? Chọn khoản đó" | Liên kết gắn với giao dịch có sẵn (`transactionId`), không tạo khoản mới |

## Thành phần mới

- **Nhóm radio có dòng phụ:** thẻ nhóm trắng, mỗi dòng 64: icon 32, tiêu đề + dòng phụ, nút tròn bên phải. Dùng khi hai lựa chọn cần một câu giải thích; thay cho hai thẻ chọn cạnh nhau khi chữ dài.
- **Dòng công tắc trong form:** thẻ trắng cao 60, tiêu đề + dòng phụ, công tắc bên phải. Dùng cho "Số tiền mỗi kỳ có thể khác", "Tạm dừng".
- **Nút "Đã trả" trên dòng:** viên thuốc đen cao 32, chữ 13 600.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Cách ghi | `mode`: `auto` / `remind`. Mặc định khi thêm: `remind` |
| Số tiền thay đổi | `amountKind`: `estimated` khi bật công tắc, `fixed` khi tắt |
| Nhắc trước | `remindDaysBefore` 0–30; app chỉ đưa 0 / 1 / 3 / 7, mặc định 3 |
| Một lần | `repeat: false` |
| Đã trả | `POST /recurring-transactions/{id}/confirm` với `amountMinor`, `accountId`, `paidOn`; hoặc `transactionId` để gắn khoản có sẵn |
| Tạm dừng | `active: false` |
