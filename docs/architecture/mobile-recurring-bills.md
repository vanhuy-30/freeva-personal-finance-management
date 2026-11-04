# Định kỳ và hóa đơn trên app — MOB-P3-001

Một màn **Định kỳ và hóa đơn** (`/me/recurring`, qua AuthGate, không bottom nav) thay hai màn cũ. Contract: [bills.md](bills.md), [recurring.md](recurring.md), OpenAPI `/recurring-transactions`. Thiết kế: [patterns/L-recurring-bills.md](../brand/patterns/L-recurring-bills.md), board `RecList`, `RecEdit`, `RecEditAuto`, `BillPaid`.

## Hành vi

- Vào từ Cá nhân → "Định kỳ". Dòng "Hóa đơn" và route `/me/bills` đã bỏ (API `/bills` trả 410).
- Danh sách: thẻ "Cần trả X · N hóa đơn chưa trả · xem trên lịch" (mở `/me/calendar`) cộng từ các rule `remind` đang bật cùng loại tiền (ưu tiên tiền tệ hồ sơ; hóa đơn ước tính tính theo số ước tính). Nhóm **CẦN TRẢ** (rule `remind`, hạn gần nhất trước; rule tạm dừng xuống cuối, không có nút) và **GHI TỰ ĐỘNG** (rule `auto`, "Ngày 5 hằng tháng", số có dấu). Tag: "Quá hạn" lấy từ `overdue` của API; "Hôm nay" / "Còn N ngày" khi hạn trong 7 ngày; "Tạm dừng".
- "Đã trả" mở sheet: số thật (điền sẵn số của rule), ví trả (mặc định ví của rule, cùng loại tiền), ngày trả (mặc định hôm nay). Gọi `POST /recurring-transactions/{id}/confirm` với `occurredOn` = `nextExecutionDate`; chỉ gửi `amountMinor` khi khác số của rule và `paidOn` khi khác hôm nay. "Đã ghi khoản chi này rồi? Chọn khoản đó" chọn trong 30 khoản chi gần nhất và gửi `transactionId` (không tạo giao dịch mới). Bấm lại hoặc thử lại cùng hạn trả kết quả cũ (`replayed`), không ghi hai lần.
- Thêm/sửa: Chi · Thu · Chuyển; nhóm radio "Ghi tự động" / "Hỏi trước khi ghi" (mặc định hỏi trước); tên, số tiền, công tắc "Số tiền mỗi kỳ có thể khác" (`amountKind`), Lặp lại (Một lần chỉ cho hóa đơn, còn lại Hằng ngày/tuần/tháng/năm), Hạn đầu tiên / Lần tới, chip Nhắc trước 0/1/3/7 (mặc định 3), ví, danh mục. Sửa có "Tạm dừng" (`active`) và "Xoá định kỳ" (có hộp xác nhận).
- Thu và Chuyển chỉ ghi tự động: API chỉ cho hóa đơn (`remind`) là khoản chi có tên, không có chân đối ứng. Dòng "Hỏi trước khi ghi" mờ đi khi chọn Thu/Chuyển.
- Loại và cách ghi của rule đã tạo không đổi được (`PATCH` không nhận `type`/`mode`), nên hiện chỉ đọc.

## Layer

`recurring/{domain,data,presentation}`. `RecurringRule` thêm `mode`, `name`, `amountKind`, `remindDaysBefore`, `overdue`, `accountId` nullable; `RecurringDraft` thêm `repeat`; `RecurringConfirm` / `RecurringConfirmResult`. Use case kiểm tra: hóa đơn cần tên, là khoản chi, số âm; rule tự ghi cần ví; xác nhận chỉ cho rule `remind`, số dương, không vừa gắn khoản chi vừa đổi số. `RecurringViewModel` nhận thêm `WalletViewModel`, `ProfileViewModel`, `TransactionUseCases`. Tiền là `BigInt`, định dạng theo `minorDigits`. Không log số tiền hay tên.

## Khác biệt có chủ ý so với board

- Tiêu đề sheet "Đã trả {tên}?" giữ nguyên hoa/thường của tên (board viết "tiền điện" thường).
- Danh mục trống ở hóa đơn hiện "Chọn danh mục" (board luôn có danh mục); hóa đơn không bắt buộc danh mục.
- Danh sách chọn khoản chi gắn sẵn chưa vẽ trên board; dùng sheet danh sách đơn giản theo token.
- Lịch (`/calendar`) vẫn trả và hiển thị mục `bills` như trước; không đổi.

## Test

Use case (hóa đơn, xác nhận), ViewModel qua màn: tổng "Cần trả" và số hóa đơn tính từ dữ liệu giả có số khác board, "Đã trả" gửi đúng `occurredOn`/ví/số thật, form lưu hóa đơn đúng `mode`/`amountKind`/nhắc trước. Golden sáng/tối (và 1.3×): danh sách, thêm hóa đơn, sửa ghi tự động, sheet Đã trả. Đối chiếu board ↔ golden: `apps/mobile/tool/design_compare` (nhóm `L`).
