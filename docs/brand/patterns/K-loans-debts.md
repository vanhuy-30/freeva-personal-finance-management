# Nhóm K — Vay và nợ

Trạng thái: **chốt thiết kế 2026-11-03**, chưa code. Task: `MOB-P3-E02` (khoản vay) và `MOB-P3-007` (cho mượn, đi mượn); API `BE-P3-E02`, `BE-P3-007` xong.
Canvas: trang **07 · Phase 3**, hàng K. Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Một màn "Vay và nợ" với công tắc **Người quen · Khoản vay**. Vào từ ô "Vay và nợ" ở Cá nhân → Quản lý tiền.
- Cho mượn / đi mượn **không tính vào thu chi**; chỉ di chuyển tiền giữa ví và khoản nợ.
- Khoản vay: chỉ **tiền gốc** làm giảm số còn nợ; tiền lãi là chi phí.
- Loại khoản vay trên app: **Vay mua nhà · Vay tiêu dùng · Khác**. Loại `card` của API không hiện; trả góp thẻ nằm ở nhóm M, thẻ tín dụng nằm ở Ví.
- Sheet ghi tiền luôn nằm trên màn chi tiết thật của khoản đó.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Người quen · chưa có | Công tắc, minh hoạ, "Chưa ai nợ ai", một dòng phụ, nút "Ghi khoản mượn" | |
| 2 | Người quen | Hai ô tổng: "Người khác nợ bạn" (xanh) · "Bạn đang nợ". Nhóm "AI NỢ BẠN" và "BẠN NỢ AI": avatar chữ cái, tên, "Cho mượn 12/10 · hạn 30/10", số còn lại, tag hạn (Còn N ngày / Quá hạn). Dòng "Đã xong (4)" | Tag hạn chỉ hiện khi ≤ 14 ngày hoặc đã quá |
| 3 | Ghi khoản mượn | Công tắc "Cho mượn · Đi mượn". Số tiền lớn. Người mượn, Lấy từ ví (kèm số dư), Ngày + Hạn trả (một hàng), Ghi chú. "Không tính vào thu chi." "Lưu" | Đi mượn: "Người cho mượn", "Vào ví" |
| 4 | Chi tiết khoản mượn | Thẻ wash: "Tuấn còn nợ bạn" số còn lại / gốc, "Đã thu …". Thông tin: ngày, hạn, ví, ghi chú. Lịch sử. Nút "Ghi tiền nhận lại" | Bạn đi mượn: "Bạn còn nợ Chị Lan", nút "Ghi tiền đã trả"; bố cục giữ nguyên, không vẽ riêng |
| 5 | Ghi tiền nhận lại (sheet trên 4) | "Tuấn trả bạn". Số tiền, chip "Một nửa" · "Tất cả 2.000.000". Vào ví + Ngày. "Thu đủ thì khoản này chuyển sang Đã xong." "Lưu" | |
| 6 | Khoản vay | Thẻ wash "Còn nợ" + hai ô "Đã trả gốc" · "Tháng này cần trả". Mỗi khoản: icon theo loại, tên, "12%/năm · kỳ tới 25/10", số còn nợ, tag hạn | "Tháng này cần trả" cộng mọi kỳ rơi vào tháng hiện tại |
| 7 | Chi tiết khoản vay | Thẻ wash: còn nợ / gốc, "Đã trả 30% gốc · xong vào 10/2035". Thẻ "Kỳ tới · 25/10: Gốc … · lãi …" + "Ghi lần trả". "Cách tính" một đoạn ngắn. Lịch trả 3 kỳ + "Xem cả lịch" | |
| 8 | Thêm khoản vay | Chip loại. Tên. Mục **SỐ TIỀN**: Số vay ban đầu + Còn nợ, Lãi suất + Trả mỗi kỳ. Mục **LỊCH TRẢ**: Kỳ trả + Kỳ tới, Bắt đầu + Kết thúc, Trả từ ví. Gợi ý "Để trống 'Trả mỗi kỳ', Freeva tự tính theo ngày kết thúc." "Lưu khoản vay" | |
| 9 | Ghi lần trả (sheet trên 7) | "Trả kỳ 25/10". Số tiền, hai ô Tiền gốc · Tiền lãi (sửa được), Trả từ ví (một dòng đủ rộng). "Chỉ tiền gốc làm giảm số còn nợ." "Lưu" | |

## Thành phần mới

- **Avatar chữ cái:** tròn 40, nền tint theo tên, chữ cái đầu 600.
- **Tag hạn:** dùng chung cho nợ, khoản vay, hóa đơn: "Còn N ngày" (`status.warningBg`), "Quá hạn" (`status.dangerBg`).
- **Hàng kỳ trả:** ngày, tag "Kỳ tới", dòng phụ gốc · lãi, số tiền bên phải.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Người quen | `/personal-debts` hướng `lent` / `borrowed`; ghi trả từng phần `POST /personal-debts/{id}/payments`; hai ô tổng từ `GET /personal-debts/summary` |
| Khoản vay | `/loans`, lịch `GET /loans/{id}/schedule`, ghi trả `POST /loans/{id}/payments` tách gốc / lãi; ô tổng từ `GET /loans/summary` |
| Loại `card` | API vẫn nhận; app không cho chọn |
| Nhắc hạn | Thông báo "Nợ đến hạn" ở Thông báo (nhóm N) |
