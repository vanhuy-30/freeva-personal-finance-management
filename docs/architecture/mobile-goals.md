# Mục tiêu trên app — MOB-P3-E01

Màn **Mục tiêu** (`/me/goals`, qua AuthGate, không bottom nav). Contract: [goals.md](goals.md). Thiết kế: [patterns/I-goals.md](../brand/patterns/I-goals.md), board `Goal*.dc.html` và `BHomeGoal.dc.html`.

## Hành vi

- Vào từ Cá nhân → Quản lý tiền → "Mục tiêu" (kèm số mục tiêu thật) và từ khối Mục tiêu trên Tổng quan.
- Danh sách: thẻ "Đã để dành" (tổng và "Tháng này cần góp" cộng các mục tiêu cùng loại tiền; ưu tiên tiền tệ hồ sơ), mỗi mục tiêu một thẻ. Chỉ báo **Quá hạn** (đỏ) hoặc **Đã đủ** (xanh); không có nhãn "Đúng hạn". Mục tiêu đã lưu trữ nằm sau dòng cuối.
- Chưa có mục tiêu: màn trống với ba chip gợi ý (Quỹ khẩn cấp, Du lịch, Mua nhà); chạm chip mở form với loại đã chọn (`/me/goals/new?kind=`).
- Tạo/sửa: loại (chip có icon), tên (tự điền theo loại tới khi sửa tay), số cần có, đã có, ngày đạt, ví giữ tiền. Thẻ xanh "Cần góp X mỗi tháng" tính ngay trên máy bằng đúng công thức của API (`goal_math.dart`, test 120.000.000 − 40.000.000 / 10 tháng = 8.000.000); "khoảng N% thu nhập" chỉ hiện khi hồ sơ có `monthlyIncomeMinor` cùng tiền tệ. Khi sửa: ví không đổi được, đổi "Đã có" là sửa số (không chuyển tiền, một dòng audit), có "Lưu trữ mục tiêu".
- Chi tiết: đã có / đích, thanh, ba ô số, "Góp thêm" và "Rút ra", lịch sử (`GET /goals/{id}/entries`: góp, rút, sửa số).
- Góp/rút (sheet): lấy từ ví khác = chuyển ví cân hai chân, không tính chi tiêu; "Đã nằm trong {ví giữ}" chỉ ghi nhận. Rút không vượt số đã có (chặn ở client, server vẫn kiểm). `clientId` giữ nguyên khi thử lại cùng nội dung.
- Tổng quan: khối "Mục tiêu · Xem tất cả" (tối đa 2) dưới thẻ số dư, chỉ khi hồ sơ chọn "Tiết kiệm" và có mục tiêu.

## Layer

`goals/{domain,data,presentation}`; repository, use case và `GoalViewModel` đăng ký qua injectable. Tiền là `BigInt`, định dạng theo `minorDigits` của loại tiền. Đổi auth stage xóa state; 401 đưa về đăng nhập. Không log số tiền hay tên mục tiêu.

## Khác biệt có chủ ý so với board

- Màu và icon theo **loại** mục tiêu, vẽ như board (xanh lá, xanh dương, tím, cyan, vàng, đỏ, trung tính). Mobile không dùng `icon`/`colorToken` backend trả về; tạo mới không gửi hai trường đó nên server dùng preset.
- Lịch sử ghi "Góp từ ví khác" thay vì tên ví: ledger chỉ lưu `transactionClientId`, chưa trả tên ví.
- Dòng "Sửa số đã có" không có số mới: audit không lưu số.
- "Đã đủ từ dd/MM" lấy từ `updatedAt` nên sai nếu mục tiêu bị sửa sau khi đủ.
- "Ngày đạt" chọn ngày trên lịch, hiện `MM/yyyy`.
- Thêm dòng "Lưu trữ mục tiêu" trong form sửa (board chưa vẽ).

## Test

Công thức, ViewModel và luồng form/sheet có test; golden sáng/tối (và 1.3×) cho danh sách, trống, tạo, chi tiết, sheet góp/rút, khối Tổng quan. Đối chiếu board ↔ golden: `apps/mobile/tool/design_compare` (nhóm `I`).
