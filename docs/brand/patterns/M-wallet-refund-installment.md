# Nhóm M — Ví, hoàn tiền, trả góp

Trạng thái: **chốt thiết kế 2026-11-03**, chưa code. Task: `MOB-P3-005` (khớp số dư), `MOB-P3-008` (hoàn tiền), `MOB-P3-009` (trả góp thẻ); API xong.
Canvas: trang **07 · Phase 3**, hàng M. Spec chung: [design-system.md](../design-system.md). Nền tảng ở [D-wallets.md](D-wallets.md) và [C-transactions.md](C-transactions.md).

## Nguyên tắc riêng cho nhóm này

- Khoản chênh khi khớp số dư là **khoản điều chỉnh**, không tính vào thu chi.
- Hoàn tiền gắn với khoản chi gốc và **trừ vào chi của danh mục đó**, không tính là thu.
- Trả góp chỉ cho khoản chi trên thẻ tín dụng. Khoản mua vẫn tính một lần vào tháng mua; mỗi kỳ cộng vào số phải trả của thẻ.
- Sheet và popup luôn nằm trên màn thật (chi tiết ví, chi tiết thẻ).
- Dữ liệu mẫu nhất quán: **Điện thoại 24.000.000** là khoản chuyển thành trả góp; **Áo khoác 890.000** là khoản được hoàn 300.000.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Khớp số dư ví (sheet trên chi tiết ví) | "Khớp số dư Vietcombank". "Số dư trên app" bên phải. Ô nhập lớn "Số dư thật trong app ngân hàng". Dải màu "Chênh lệch +212.000". "Phần chênh ghi thành khoản điều chỉnh, không tính vào thu chi." "Khớp số dư" | Chênh âm: dải đỏ nhạt |
| 2 | Chi tiết khoản chi (sheet trên chi tiết thẻ) | Icon, tên, số tiền. Danh mục, Ví, Thời gian. Hai hàng hành động: "Ghi hoàn tiền · Đổi trả, hoàn một phần", "Chuyển thành trả góp · Chia nhiều kỳ trên thẻ". Xoá · Sao chép · Sửa | Có hoàn tiền: thêm dòng "Đã hoàn +…". "Chuyển thành trả góp" chỉ hiện với khoản chi trên thẻ chưa trả góp |
| 3 | Ghi hoàn tiền (sheet) | "Hoàn tiền Áo khoác", "Đã chi 890.000 · 12/10". Số tiền hoàn lớn, chip "Hoàn toàn bộ 890.000". Vào ví, Ngày (mỗi ô một dòng). "Trừ vào chi Mua sắm tháng 10, không tính là thu." "Ghi hoàn tiền" | |
| 4 | Xoá khoản chi có hoàn tiền (popup) | "Xoá khoản chi này?", "Khoản này đã được hoàn 300.000." Hai lựa chọn: "Xoá cả hoàn tiền · Ví bớt đi 300.000" (mặc định) · "Giữ hoàn tiền · Chuyển thành một khoản thu". Huỷ · Xoá | |
| 5 | Chuyển thành trả góp | Đóng · "Trả góp". Thẻ khoản mua. Chip Số kỳ 3 / 6 / 9 / 12 / Khác. Mỗi kỳ (sửa được) + Kỳ đầu. Xem trước 3 kỳ + "… thêm 3 kỳ, xong 25/04/2027". Gợi ý một dòng. "Tạo lịch trả góp" | "Khác" mở ô nhập 2–60 |
| 6 | Lịch trả góp | Thẻ "Còn phải trả" / tổng, thanh tím, "Đã trả 1/6 kỳ · Thẻ chính". Danh sách kỳ: kỳ đã qua có dấu tích muted, "Kỳ tới". "Mỗi kỳ cộng vào số phải trả của thẻ." Nút chữ đỏ "Kết thúc trả góp" · "Dùng khi đã trả hết sớm" | |
| 7 | Chi tiết thẻ có trả góp | Như D.4, thêm thẻ "Phải trả kỳ này · 25/11" + "Gồm 4.000.000 trả góp · tối thiểu 1.545.000". Nhóm **TRẢ GÓP**: dòng "Điện thoại · Kỳ 2/6 · 25/12 · 4.000.000". Giao dịch có dòng phụ "đã hoàn 300.000" | |

## Thành phần mới

- **Dải chênh lệch:** nền `status.successBg` / `dangerBg` bo 16, icon cân, số có dấu.
- **Hàng hành động trong sheet chi tiết:** icon tint 32, tiêu đề + dòng phụ, mũi tên.
- **Popup chọn một trong hai:** thẻ radio viền 1.5 primary khi chọn, dòng phụ nói hậu quả bằng tiền.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Khớp số dư | `POST /financial-accounts/{id}/reconcile` tạo giao dịch `adjustment` |
| Hoàn tiền | `POST /transactions/{id}/refunds`; xoá khoản gốc gửi `refunds: cascade` hoặc `keep` |
| Trả góp | `POST /card-installments` (`installmentCount` 2–60, `installmentMinor` để trống thì chia đều, `firstDueOn`); kết thúc `POST /card-installments/{id}/close` |
| Số phải trả kỳ này | Cộng kỳ trả góp đến hạn (`GET /card-installments/due`) vào dư nợ kỳ |
