# Nhóm P — Đầu tư · Q — Tài sản ròng theo thời gian

Trạng thái: **chốt thiết kế 2026-11-06**, chưa code. Task: `MOB-P4-E01` (P), `MOB-P4-E02` (Q); API thêm ở `BE-P4-E03`.
Canvas: trang **08 · Phase 4** (`p4`). Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Ba tầng: **danh mục** (Vàng, Cổ phiếu, Chứng chỉ quỹ, Tiền gửi, Bất động sản, Crypto) → **tài sản** (Vàng SJC, VNM…) → **lần mua**.
- Tài sản là vị thế: một giá dùng chung, giá vốn bình quân; **Mua thêm** và **Bán** ở tài sản. Lần mua chỉ xem, sửa, xoá.
- "Lãi/lỗ dự kiến" luôn có số tiền và %. Khoản chưa có giá: tag "Chưa có giá", không vào lãi/lỗ.
- Thẻ tổng kiểu A2: nền xanh nhạt, đường giá trị mờ phía sau số; chưa đủ hai điểm lịch sử thì ẩn đường.
- Câu chữ tối thiểu: không câu giải thích dưới ô nhập, không chú thích số.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| P.1 | Đầu tư · chưa có | Icon, "Chưa có khoản đầu tư", ba chip loại, "Thêm khoản đầu tư" | |
| P.2 | Đầu tư | Thẻ tổng (giá trị, pill %, Vốn · Lãi/lỗ dự kiến). Thẻ "Tỷ trọng theo danh mục" (vòng + chú thích, chạm mở danh mục). **DANH MỤC**: mỗi danh mục một thẻ (icon, tên, các tài sản, pill %, ba cột Giá trị · Vốn · Lãi/lỗ dự kiến). "Đã bán hết" | Tiền gửi có một khoản thì mở thẳng P.11 |
| P.3 | Danh mục Vàng | Thẻ tổng của danh mục. Mỗi tài sản một thẻ: tên, số lượng, pill %, ô giá "8.000.000/chỉ · 05/11 · Cập nhật giá", ba cột số, **CÁC LẦN MUA** (ô ngày, số lượng, giá mua, số tiền, %), Mua thêm · Bán. Dòng "Đã bán" | Lần mua có sẵn: ô ngày "— / có sẵn" tô vàng |
| P.4 | Chi tiết một lần mua | Thẻ tổng của lần mua (giá trị, %, vốn, lãi/lỗ). Danh sách: Ngày mua, Số lượng, Giá mua, Lấy từ ví, Giá hiện tại (mở P.10), Ghi chú. Sửa · Xoá | Lần mua có sẵn: dòng ví ghi "Đã có từ trước" |
| P.5 | Khoản mới | **DANH MỤC** chip, Tên tài sản, Chỉ/Lượng (chỉ vàng), Số lượng · Giá mua một chỉ, Ngày mua, Tổng tiền (tự tính), **LẤY TỪ VÍ** các ví + "Đã có từ trước · Không trừ ví", Ghi chú | Trùng tên tài sản thì vào tài sản đó. Danh mục khác bỏ ô chỉ/lượng; bất động sản số lượng 1 |
| P.6 | Khoản mới · tiền gửi | Tên, Số tiền gửi, Lãi suất/năm, Ngày gửi, Ngày đáo hạn, **LẤY TỪ VÍ** (có "Đã có từ trước"), Ghi chú | |
| P.7 | Sửa lần mua | Số lượng, Giá mua, Ngày, Tổng tiền, Lấy từ ví, Ghi chú, Lưu, "Xoá lần mua này" | |
| P.8 | Xoá lần mua (sheet) | "Xoá lần mua 10/09?", "5 chỉ Vàng SJC", dòng "Trả lại Tiền mặt +35.000.000", Xoá · Giữ lại | Đã bán nhiều hơn số còn lại thì chặn xoá |
| P.9 | Bán (sheet, trên P.3) | Tiền nhận, Số lượng bán · Giá bán (điền sẵn giá hiện tại), "Bán hết 7 chỉ", Ngày bán, **TIỀN VỀ VÍ**, "Lãi chốt +2.571.429" | Giá bán thành giá hiện tại; lãi chốt theo giá vốn bình quân |
| P.10 | Cập nhật giá (sheet) | Giá một chỉ, giá trước, Ngày báo giá, Lưu giá | Giá theo tài sản |
| P.11 | Chi tiết tiền gửi | Thẻ tổng (Gốc · Lãi tạm tính), Lãi suất, Ngày gửi, Đáo hạn · còn N ngày, Lấy từ ví, Rút tiền gửi, Sửa · Xoá | Đã đáo hạn: giá trị dừng ở ngày đáo hạn |
| P.12 | Rút tiền gửi (sheet) | Tiền nhận về (điền sẵn gốc + lãi, sửa được), Ngày rút, **VỀ VÍ** | Rút hết |
| Q.1 | Tài sản ròng | Số hôm nay, thay đổi từ đầu khoảng, biểu đồ, chip 7 ngày → Tất cả, Tài sản · Nợ, **TRONG TÀI SẢN** Ví · Đầu tư | Mở từ ô "Tài sản ròng" ở Cá nhân; chạm điểm hiện ngày và số |

Lưới Cá nhân (`MeHome3`) có thêm ô **Đầu tư** và **Tài sản ròng**.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Có sẵn | `/investments` CRUD, `summary`, `trades`, `prices`; `/reports/net-worth/history` |
| Cần `BE-P4-E03` | Xem DoD của task trong [phase-04.md](../../../tasks/phase-04.md) |
| App | Thêm `TransactionType.investment` trước khi hiện chân giao dịch này |
