# Nhóm O — Cá nhân và dữ liệu

Trạng thái: **chốt thiết kế 2026-11-03**; màn 3 (Xuất dữ liệu) **đã code** (`MOB-P3-010`), còn lại chưa code. Task: `MOB-P3-010` (xuất CSV), `MOB-P3-011` (nhập CSV); API xong. Màn Cá nhân thay bản ở [G-profile-settings.md](G-profile-settings.md).
Canvas: trang **07 · Phase 3**, hàng O. Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Cá nhân tách hai loại mục: **chỗ dùng thường xuyên** (lưới ô) và **cài đặt chỉnh một lần** (danh sách).
- Xuất có hai loại: **Bảng giao dịch** (CSV, lọc theo thời gian và ví) và **Bản sao đầy đủ** (JSON để cất giữ, không lọc).
- Nhập: nguồn → (chọn cột nếu "Nơi khác") → ghép ví và danh mục → xem trước → xong. Trùng thì bỏ qua, không ghi đè.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Cá nhân | Thẻ hồ sơ. **QUẢN LÝ TIỀN**: lưới 3 cột, 6 ô (Ví của tôi · 4 ví, Ngân sách · 15.000.000, Mục tiêu · 3 mục tiêu, Vay và nợ · 2 khoản, Định kỳ · 6 khoản, Lịch · Tháng 11). **THIẾT LẬP**: Danh mục, Nhãn · 12, Thu nhập và kỳ tính · "VND · ngày 1". **ỨNG DỤNG**, **DỮ LIỆU** (Nhập từ app khác, Xuất dữ liệu), **HỖ TRỢ**, Đăng xuất | Ô "Định kỳ" là tên rút gọn của "Định kỳ và hóa đơn" |
| 2 | Thu nhập và kỳ tính | Ba dòng: Thu nhập hàng tháng, Tiền tệ mặc định, Tháng tính từ. "Lương về giữa tháng? Đặt theo ngày lương để ngân sách và báo cáo tính đúng kỳ." | Thu nhập sửa / xoá được (`monthlyIncomeMinor`) |
| 3 | Xuất dữ liệu | Hai thẻ chọn: Bảng giao dịch · Bản sao đầy đủ. Chip thời gian (Tháng này, 3 tháng, Năm nay, Tất cả, Tuỳ chọn), Ví. "01/08 – 03/11 · 248 giao dịch". "Xuất file" | Bản sao đầy đủ: ẩn chip và ô ví |
| 4 | Nhập giao dịch | Tiêu đề lớn **"Nguồn dữ liệu"**. Thẻ chọn: Money Lover, Sổ thu chi MISA, Freeva, Nơi khác. "Tối đa 2.000 dòng mỗi lần. Giao dịch đã có sẽ được bỏ qua." "Chọn file CSV" | |
| 5 | Chọn cột (chỉ "Nơi khác") | Thẻ file "so-chi-tieu.csv · 248 dòng". **CỘT TRONG FILE**: Ngày\*, Số tiền\*, Thu hay chi, Danh mục, Ví, Ghi chú, mỗi dòng một ô chọn cột (hoặc "Không dùng"). Kiểu ngày + Kiểu số. "Dòng đầu đọc được". "Tiếp" | |
| 6 | Ghép ví và danh mục | Dải vàng "Còn 2 mục chưa ghép." **VÍ TRONG FILE** / **DANH MỤC TRONG FILE**: tên trong file → ô chọn mục Freeva; chưa ghép là ô viền đứt vàng "Chọn". "Xem trước" | Mũi tên → giữa hai cột, không dùng › |
| 7 | Xem trước | Ba ô: Sẵn sàng · Trùng · Lỗi. Chip lọc. Dòng có tag "Trùng" / "Thiếu ngày". Công tắc "Vẫn nhập khoản trùng · Thường bạn không cần bật". "Nhập 241 giao dịch" | |
| 8 | Đã nhập xong | Dấu tích lớn, "Đã nhập 241 giao dịch", "Bỏ qua 5 khoản trùng và 2 dòng lỗi." "Xem giao dịch" · nút chữ đỏ "Hoàn tác lần nhập" · "Khoản bạn đã sửa sau khi nhập sẽ được giữ lại." | |

## Thành phần mới

- **Ô quản lý (lưới Cá nhân):** thẻ trắng bo 20, đệm 12, icon tint 36 bo 11, tên 14 600 một dòng, giá trị 12 muted. Lưới 3 cột, khe 8.
- **Dòng ghép:** tên nguồn bên trái, mũi tên → muted, ô chọn đích (icon + tên + ▾) hoặc ô viền đứt khi chưa ghép.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Xuất CSV | `GET /transactions/export.csv` (cùng bộ lọc danh sách, tối đa 50.000 dòng); chia sẻ file qua share sheet |
| Bản sao đầy đủ | `GET /account/export` (JSON) |
| Nhập | `POST /transactions/import/preview` (không ghi), `POST /transactions/import` (`batchClientId`, `includeDuplicates`), `POST /transactions/import/{id}/undo` |
| Preset | `freeva`, `money_lover`, `misa`, `custom`; `dateFormat` `iso/dmy/mdy`, `numberFormat` `plain/dot_thousands/comma_thousands` |
| Hoàn tác | Bỏ qua khoản đã sửa hoặc đã có hoàn tiền / trả góp |
