# Nhóm I — Mục tiêu

Trạng thái: **chốt thiết kế 2026-11-03**, chưa code. Task: `MOB-P3-E01` (API `BE-P3-E01` xong).
Canvas: trang **07 · Phase 3**, hàng I
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Vào từ ô "Mục tiêu" ở Cá nhân → Quản lý tiền, hoặc khối Mục tiêu trên Tổng quan. Mọi màn là màn tiếp theo, **không có bottom nav**.
- Tiền của mục tiêu vẫn nằm trong một ví ("Giữ ở ví"). Góp vào = chuyển ví hoặc chỉ ghi nhận; **không tính là chi tiêu**.
- Loại mục tiêu chọn bằng chip có icon (giống chip loại khoản vay), không dùng lưới thẻ.
- Không có nhãn "Đúng hạn". Chỉ báo khi có việc: **Quá hạn** (đỏ) hoặc **Đã đủ** (xanh).

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Chưa có mục tiêu | Minh hoạ, "Chưa có mục tiêu", một dòng phụ, ba chip gợi ý (Quỹ khẩn cấp, Du lịch, Mua nhà), nút "Tạo mục tiêu" | Chạm chip mở 3 với loại đã chọn |
| 2 | Mục tiêu | Thẻ wash "Đã để dành" tổng + hai ô "Mục tiêu · 3" và "Tháng này cần góp". Mỗi mục tiêu: icon, tên, `đã có / đích`, thanh, %, dòng phụ ("Còn 10 tháng · cần 8.000.000 mỗi tháng"). Dòng "Mục tiêu đã lưu trữ" | Quá hạn: "Hạn 30/09 đã qua · còn thiếu …". Đã đủ: "Đã đủ từ 12/09" |
| 3 | Mục tiêu mới | Đóng · "Mục tiêu mới". Chip loại (8 loại + Khác). Tên, Số cần có + Đã có (một hàng), Ngày đạt, Giữ ở ví (hiện số dư ví). Thẻ xanh "Cần góp 8.000.000 mỗi tháng, khoảng 32% thu nhập." "Tạo mục tiêu" | % thu nhập chỉ hiện khi hồ sơ có `monthlyIncomeMinor` |
| 4 | Chi tiết mục tiêu | Thẻ wash: đã có / đích, thanh, "33% · còn thiếu …". Ba ô: Cần mỗi tháng, Còn, Ngày đạt. Dòng "Giữ ở ví". Nút "Góp thêm" (primary) · "Rút ra". Lịch sử: góp từ ví khác, ghi nhận tiền đã ở sẵn, sửa số đã có | |
| 5 | Góp / rút (sheet trên 4) | Công tắc "Góp vào · Rút ra". Số tiền lớn. "Lấy từ": danh sách ví có số dư, cuối cùng là "Đã nằm trong {ví giữ} · Chỉ ghi nhận, không chuyển tiền". Gợi ý "Ghi thành chuyển ví, không tính là chi tiêu." Nút "Góp 5.000.000 ₫" | Rút ra: đảo chiều, chọn ví nhận |
| 6 | Tổng quan có khối mục tiêu | Khối "Mục tiêu · Xem tất cả" ngay dưới thẻ số dư, tối đa 2 mục tiêu có thanh | Hiện khi người dùng chọn "Tiết kiệm" ở onboarding (A3) và có ít nhất một mục tiêu |

## Thành phần mới

- **Thẻ mục tiêu:** icon 40 bo 12, tên + `đã có / đích`, thanh 8, % bên phải, dòng phụ một dòng. Trạng thái Quá hạn / Đã đủ bằng tag màu, thanh đổi màu theo.
- **Chip có icon:** cao 44, icon 24 bo 8 + chữ một dòng; chip chọn viền 1.5 ink. Dùng chung cho loại mục tiêu, loại khoản vay, nhóm tiết kiệm ở onboarding.
- **Thẻ "Cần góp":** nền `status.successBg`, số tiền đậm màu thu, kèm % thu nhập.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Góp / rút | `POST /goals/{id}/contribute`, `/withdraw`; lấy từ ví khác tạo chuyển ví, "Đã nằm trong …" chỉ ghi nhận |
| Sửa số đã có | `POST /goals/{id}/adjust`, hiện trong lịch sử là "Sửa số đã có" |
| % thu nhập | Lấy `monthlyIncomeMinor` từ hồ sơ (A3); không có thì ẩn phần % |
| Lưu trữ | Mục tiêu đã lưu trữ nằm sau dòng cuối danh sách |
