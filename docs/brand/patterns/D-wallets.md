# Nhóm D — Ví

Trạng thái: **chốt thiết kế 2026-10-21**, chưa code. Task: `DS-P2-003` (màn Ví).
Canvas: trang **05 · Patterns**, hàng D
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Vào từ nút nhanh "Ví của tôi" (Tổng quan) hoặc Cá nhân → Quản lý. Mọi màn trong nhóm là màn tiếp theo nên **không có bottom nav**.
- Bốn loại ví, mỗi loại một icon hai tông cố định: Ngân hàng `tint.blue` · Tiền mặt `tint.cyan` · Ví điện tử `tint.violet` · Thẻ tín dụng `bg.subtle` + ink.
- Không xoá ví, chỉ **ẩn**; ẩn không hỏi lại, có toast Hoàn tác, khôi phục ở "Ví đã ẩn".
- Ví đã có giao dịch thì khoá loại ví và tiền tệ.
- Chữ giải thích tối thiểu: lý do khoá đọc qua nhãn trợ năng, trên màn chỉ có icon ổ khoá.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Ví của tôi | Quay lại · "Ví của tôi" · nút +. "Tổng số dư · 4 ví" `moneyL` + "Sắp xếp". Thẻ list: icon loại, tên, loại, số dư. Dòng thẻ tín dụng thêm "đến hạn 25/10" và thanh hạn mức 6. Dòng "Ví đã ẩn · 1" | Chạm ví mở 3 hoặc 4 |
| 2 | Sắp xếp ví | "Sắp xếp ví" · "Xong". "Giữ và kéo, hoặc dùng mũi tên." Mỗi dòng: tay kéo, icon, tên, nút lên/xuống (khoá ở đầu/cuối danh sách). Dòng đang kéo nghiêng nhẹ, viền primary; chỗ thả nền `tint.blue` viền đứt | Mũi tên cho trình đọc màn hình và người không kéo được |
| 3 | Chi tiết ví | Quay lại · tên ví · nút sửa. Thẻ số dư wash: "Ngân hàng · VND", số dư, "Vào / Ra tháng 10". Nút "Ghi từ ví này" · "Chuyển ví". Giao dịch của ví theo ngày | Chuyển ví hiện muted, không dấu |
| 4 | Chi tiết thẻ tín dụng | Thẻ wash: "Dư nợ", số, thanh hạn mức, "Còn dùng được … · Hạn mức …". Thẻ thông tin: "Đến hạn thanh toán 25/10" + chip "còn 4 ngày", "Ngày chốt sao kê · Ngày 20 hằng tháng". Nút "Ghi từ thẻ này" · "Trả thẻ" (mở Chuyển ví, đích là thẻ) | Chip đến hạn khi còn ≤ 7 ngày; thanh theo ngưỡng ở [B-overview.md](B-overview.md) |
| 5 | Thêm ví | Đóng · "Thêm ví". Loại ví: thẻ chọn 2×2, icon và chữ một dòng. Tên ví, Tiền tệ (ô chọn), Số dư hiện tại (để trống = 0) + "Nhập số gần đúng, có thể sửa lại sau." "Lưu ví" | Modal |
| 6 | Thêm thẻ tín dụng | Như 5, loại "Thẻ tín dụng". Tên thẻ, Tiền tệ, Dư nợ hiện tại + Hạn mức (một hàng), Ngày chốt + Đến hạn (một hàng, icon lịch ở đầu ô). "Hạn mức và ngày có thể để trống." "Lưu thẻ" | Dư nợ lưu thành số dư ban đầu âm |
| 7 | Chọn ngày (popup) | Hộp thoại giữa màn: icon, "Đến hạn ngày nào? · Hằng tháng", lưới 1–28, ngày chốt có chấm xám. "Huỷ" · "Chọn ngày 25" | Popup, không phải sheet. Chỉ 1–28 |
| 8 | Sửa ví đã có giao dịch | Tên ví. Ô khoá "Loại ví · Tiền tệ — Ngân hàng · VND" với icon ổ khoá. Số dư ban đầu. Nút chữ "Ẩn ví". "Lưu thay đổi" | Ví chưa có giao dịch: hai lựa chọn này mở như màn 5 |
| 9 | Ví đã ẩn | "Ví đã ẩn" · "Lịch sử vẫn giữ, khôi phục lúc nào cũng được." Dòng ví màu nhạt, nút "Khôi phục" | |

## Thành phần mới (bổ sung vào design system)

- **Dòng ví:** icon 40 bo 12 hai tông theo loại, tên + loại, số dư tabular bên phải; thẻ tín dụng thêm thanh hạn mức 6.
- **Chế độ sắp xếp:** dòng thẻ trắng 64, tay kéo 6 chấm, nút mũi tên 40; dòng đang kéo nghiêng −1°, viền 1.5 primary, bóng elevation 2+; chỗ thả `tint.blue` viền đứt `blue.200`.
- **Thẻ chọn một dòng:** cao 72, icon 32 + chữ trên cùng hàng, dấu tích ở góc. Dùng chung cho mọi lưới thẻ chọn trong form.
- **Ô chọn có icon đầu:** ô 60 có ô icon 32 bên trái (ngày chốt: lịch có dấu tích; đến hạn: lịch có đồng hồ, nền `status.warningBg`).
- **Popup chọn ngày trong tháng:** hộp thoại bo 28, lưới 7 cột, ngày chọn nền primary, ngày liên quan có chấm; hai nút Huỷ (secondary) và xác nhận (primary).
- **Ô khoá:** nền `bg.subtle`, chữ `text.onWash`, icon ổ khoá; nhãn trợ năng nói lý do khoá.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Tổng số dư và ví đã ẩn | Đã chốt ở `DS-P2-003`: API net-worth bỏ ví đã ẩn khỏi tổng, khớp "· 4 ví". |
| Ví có giao dịch hay chưa | Cần cờ từ API để khoá loại/tiền tệ trước khi người dùng sửa, thay vì báo lỗi lúc lưu. |
| Kéo để sắp xếp | Xong (D1): `PUT /financial-accounts/order` lưu cả thứ tự một lần. Kéo dùng `ReorderableListView`: chỗ thả là khoảng trống, chưa có ô viền đứt `tint.blue`. |
| Ngày đến hạn kế tiếp, "còn N ngày" | Tính từ `dueDay` theo ngày trên máy, cùng cách khối thẻ ở Tổng quan (chưa theo múi giờ hồ sơ). |
| Vào / Ra tháng | Chốt 2026-10-23: tính cả chuyển ví vào/ra. `summary` thêm `transferInMinor` / `transferOutMinor`. |
| Dòng chuyển ví trong chi tiết ví | API lọc theo ví chỉ trả leg của ví đó, nên dòng chưa ghi "Sang MoMo"; tiêu đề là ghi chú hoặc "Chuyển ví". |
| Trả thẻ | Là Chuyển ví với ví đích là thẻ; hai leg cân bằng như mọi chuyển ví. |
| Toast Hoàn tác khi ẩn | Hoàn tác = khôi phục ngay. |
| Copy l10n | Thay các chuỗi `wallet*` dài hiện có (`walletMoneyHint`, `walletEditHint`, `walletHideExplanation`…) bằng chữ ngắn ở trên. |
