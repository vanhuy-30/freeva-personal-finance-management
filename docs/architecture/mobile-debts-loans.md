# Vay và nợ trên app — MOB-P3-007 / MOB-P3-E02

Màn **Vay và nợ** (`/me/debts`, qua AuthGate, không bottom nav) với công tắc **Người quen · Khoản vay** (`?tab=loans` mở thẳng tab Khoản vay). Contract: [personal-debts.md](personal-debts.md), [loans.md](loans.md). Thiết kế: [patterns/K-loans-debts.md](../brand/patterns/K-loans-debts.md), board `Debt*.dc.html`, `Loan*.dc.html`.

## Hành vi

- Vào từ Cá nhân → Thiết lập tài chính → "Vay và nợ" (kèm số khoản mượn đang mở + khoản vay chưa trả xong). Hộp thư `debt_due` / `debt_overdue` mở khoản đó (`params.debtId`); push loại `debt` mở `/me/debts`.
- **Người quen** (`MOB-P3-007`): hai ô "Người khác nợ bạn" · "Bạn đang nợ" lấy từ `GET /personal-debts/summary` (`totals`, ưu tiên tiền tệ hồ sơ); nhóm AI NỢ BẠN / BẠN NỢ AI (mới nhất trước), avatar chữ cái (chữ đầu của tên cuối, màu theo tên), tag "Còn N ngày" khi ≤ 14 ngày, "Quá hạn" khi đã quá; "Đã xong (n)" mở nhóm đã tất toán tại chỗ. Chưa có gì: màn trống + "Ghi khoản mượn".
- Ghi khoản mượn: Cho mượn · Đi mượn, số tiền, người, ví (kèm số dư, ẩn khi bật "Ẩn số dư"), ngày + hạn trả, ghi chú. `clientId` giữ cho cả màn nên bấm Lưu lại không ghi hai lần. Sửa: chỉ người, hạn trả, ghi chú (API không cho đổi số tiền, chiều, ví).
- Chi tiết: còn lại / gốc, thanh đã thu (đã trả), thông tin, lịch sử (`GET …/payments` + dòng tạo khoản). Sheet "Ghi tiền nhận lại" / "Ghi tiền đã trả": chip "Một nửa" (làm tròn xuống đơn vị tiền, `halfOf`) và "Tất cả", ví cùng tiền tệ, ngày; số lớn hơn còn lại bị chặn ở client (API cũng trả 422).
- **Khoản vay** (`MOB-P3-E02`): thẻ "Còn nợ" + "Đã trả gốc" · "Tháng này cần trả" từ `GET /loans/summary` (`dueThisMonthMinor`), mỗi khoản một thẻ (icon theo loại, "12%/năm · kỳ tới 25/10", tag hạn, thanh tiến độ `percentBps`). Loại `card` của API không chọn được trên app.
- Thêm/sửa khoản vay: chip Vay mua nhà · Vay tiêu dùng · Khác, tên (tự điền theo loại tới khi sửa tay), số vay ban đầu, còn nợ, lãi suất (%/năm → bps), trả mỗi kỳ, kỳ trả, kỳ tới, bắt đầu/kết thúc (`MM/yyyy`), ví trả. Để trống "Trả mỗi kỳ" thì app tính số trả cố định theo ngày kết thúc bằng đúng công thức của API (`annuityPayment`, test 100tr · 12% · 12 tháng = 8.884.879). Sửa "Còn nợ" gọi `POST /loans/{id}/adjust` sau `PATCH`.
- Chi tiết khoản vay: còn nợ / gốc, "Đã trả N% gốc · xong vào MM/yyyy" (ngày kỳ cuối của lịch), thẻ Kỳ tới (kỳ 1 của `GET /loans/{id}/schedule`, có `dueDate`) + "Ghi lần trả", "Cách tính", 3 kỳ + "Xem cả lịch" (`/me/debts/loans/:id/schedule`).
- Sheet "Trả kỳ dd/MM": số tiền, Tiền gốc · Tiền lãi điền sẵn từ kỳ tới (đổi số tiền thì lãi giữ trước, phần còn lại là gốc; sửa một phần thì số tiền đổi theo), ví kèm số dư, ngày hôm nay. App không gửi danh mục: phần gốc là giao dịch `debt` (không tính chi tiêu), phần lãi là khoản chi "Lãi vay".
- Giao dịch loại `debt` (chân tiền của khoản mượn) (chân tiền của khoản mượn và phần gốc trả khoản vay) hiện trong danh sách và lịch sử ví là "Vay và nợ" (icon bắt tay, dấu theo chiều tiền); chi tiết không có Sửa/Xoá/Sao chép vì API từ chối.

## Layer

`debts/{domain,data,presentation}` và `loans/{domain,data,presentation}`; repository, use case, `DebtViewModel`, `LoanViewModel` đăng ký qua injectable. Tiền là `BigInt`. Đổi auth stage xoá state; 401 đưa về đăng nhập. Không log tên người hay số tiền.

## Khác biệt có chủ ý so với board

- Màu avatar theo tên (cùng người cùng màu ở mọi màn), board tô theo vị trí dòng.
- Ghi tiền khoản vay luôn là ngày hôm nay (board ghép "· hôm nay" vào dòng ví, không có ô ngày).
- "Lãi suất" vẽ đơn vị "%/năm" ở cuối ô thay vì sát số.
- Thêm "Bỏ hạn" khi đã chọn hạn trả, và màn "Xem cả lịch" dùng lại hàng kỳ trả (board chưa vẽ).

## Test

Công thức (`halfOf`, `annuityPayment`, `addPeriod`, lãi suất), repository, use case, ViewModel có test; golden sáng/tối (và 1.3×) cho 9 màn K. Đối chiếu board ↔ golden: `apps/mobile/tool/design_compare` (nhóm `K`).
