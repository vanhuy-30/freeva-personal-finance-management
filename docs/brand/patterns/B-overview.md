# Nhóm B — Tổng quan

Trạng thái: **chốt thiết kế 2026-10-21**, chưa code. Task: `DS-P2-003` (màn Tổng quan).
Canvas: trang **05 · Patterns**, hàng B
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md). Màn lần đầu (checklist "Bắt đầu nào") ở
[A-onboarding-auth.md](A-onboarding-auth.md) A1.7.

## Nguyên tắc riêng cho nhóm này

- Loại màn **Tổng quan**: lời chào, thẻ số dư có lớp màu (chỗ duy nhất có wash), menu nhanh, khối tóm tắt.
- Thứ tự từ trên xuống: lời chào + tìm + chuông → thẻ số dư → 4 nút nhanh → khối theo mục tiêu (nếu có) → Chi tháng này → Gần đây.
- Lỗi một phần không chặn cả màn: lời chào, nút nhanh và nút + luôn dùng được.
- Giữ chuông thông báo dù tính năng thông báo chưa có (`BE-P2-E05`); trước khi có thì mở màn trống.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Tổng quan | "Thứ Ba, 21/10" · "Chào Minh", nút tìm (mở C1.2), nút chuông. Thẻ số dư: "Tổng số dư · 4 ví", số `moneyDisplay`, nút mắt, hai ô Thu/Chi tháng. Nút nhanh: Ghi thu · Chuyển ví · Ví của tôi · Danh mục. Khối "Chi tháng 10" (thanh phân bổ 4 màu dữ liệu + chú thích %). "Gần đây" 3 dòng + "Xem giao dịch" | Chạm khối chi mở Báo cáo; chạm dòng mở C1.5 |
| 2 | Ẩn số dư | Chỉ tổng số dư thành `••••••`, nút mắt gạch chéo. Thu/chi, khối chi, giao dịch vẫn hiện | Xem quy tắc ẩn số dư bên dưới |
| 3 | Nhiều tiền tệ | Số lớn là tổng các ví cùng tiền tệ hồ sơ ("Tổng số dư · 4 ví VND"). Tiền tệ khác thành viên nhỏ dưới số: "1.250,00 USD · 1 ví" (chạm mở danh sách ví). Khối chi tính theo tiền tệ hồ sơ, thêm một dòng "Ví USD: chi 35,00 USD tháng này" | **Không quy đổi** giữa tiền tệ |
| 4 | Mục tiêu quản lý nợ | Người dùng chọn "Quản lý khoản nợ" ở A1.2 → khối **Thẻ tín dụng** lên trên khối chi. Mỗi thẻ: tên, thanh đã dùng / hạn mức, "Đến hạn 25/10" | Thanh: < 70% `data.1`, 70–90% `amber.500`, > 90% `red.500`. Đến hạn trong 7 ngày: chip `status.warningBg` |
| 5 | Đầu tháng | Thu/chi = 0 (chữ `text.onWash`). Khối chi: thanh rỗng, "Chưa có khoản chi nào." và nút "Ghi chi" cùng một hàng. Thẻ "Xem lại tháng 10 · Chi … · Thu …" mở Báo cáo kỳ trước | "Tháng" theo ngày bắt đầu kỳ trong hồ sơ |
| 6 | Đang tải | Lời chào, nút nhanh hiện thật; thẻ số dư giữ wash với khối skeleton trắng mờ; khối chi và Gần đây là skeleton `bg.skeleton` | Không hiện số 0 giả |
| 7 | Ngoại tuyến | Banner trong nội dung, nền `status.infoBg`: "Đang ngoại tuyến · Số liệu lúc 09:30. Vẫn ghi chi được." Dữ liệu đã lưu vẫn hiện; giao dịch chưa gửi có dòng phụ "Chờ đồng bộ" | Chi tiết hàng chờ, xung đột: nhóm H |
| 8 | Lỗi tải | Thẻ trắng thay chỗ thẻ số dư: icon lỗi, "Chưa tải được số dư", "Dữ liệu của bạn vẫn an toàn.", nút "Thử lại" (secondary) | Chỉ khi chưa có dữ liệu lưu; có dữ liệu thì dùng màn 7 |

## Quy tắc ẩn số dư

- Bật bằng nút mắt trên thẻ số dư hoặc công tắc trong Cài đặt; nhớ theo thiết bị.
- **Chỉ ẩn số dư**: tổng số dư, số dư các tiền tệ khác, số dư từng ví (danh sách ví, chi tiết ví, ô chọn ví). Thu/chi, báo cáo, số tiền giao dịch vẫn hiện.
- Hạn mức và "đã dùng" của thẻ tín dụng không phải số dư, vẫn hiện.
- Trình đọc màn hình đọc "số dư đã ẩn".
- Khác với khoá app: chưa mở khoá thì không hiện số tiền nào, kể cả ở màn chuyển app ([A-onboarding-auth.md](A-onboarding-auth.md)).

## Thành phần mới (bổ sung vào design system)

- **Viên tiền tệ phụ** trong thẻ số dư: cao 32, nền trắng 72%, số `titleM` + mã tiền tệ và số ví `label`, mũi tên.
- **Khối thẻ tín dụng:** thẻ trắng, mỗi thẻ một dòng tên + chip đến hạn, thanh tiến độ 8, dòng "Đã dùng … / Hạn mức …".
- **Banner ngoại tuyến:** nền `status.infoBg`, chữ `status.info`, icon mây gạch chéo, hai dòng.
- **Thẻ lỗi khối:** icon trong ô `status.dangerBg`, tiêu đề `titleL`, một dòng trấn an, nút secondary "Thử lại".
- **Skeleton trên wash:** khối trắng 72% thay cho `bg.skeleton` để giữ lớp màu.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Ẩn số dư chỉ ẩn số dư | `MOB-P1-009` hiện ẩn mọi số tiền (tổng quan, báo cáo, danh sách ví, danh sách giao dịch) — đổi theo quy tắc trên. |
| Khối theo mục tiêu | Cần lưu câu trả lời A1.2 vào hồ sơ (đã ghi ở nhóm A). |
| Số dư thẻ tín dụng, ngày đến hạn | Ví có `creditLimit`, `dueDay`; cần tính "đã dùng" và ngày đến hạn kế tiếp. |
| Thời điểm số liệu khi ngoại tuyến | Cần lưu thời điểm tải tổng quan gần nhất. |
| Chuông thông báo | Chưa có trung tâm thông báo; trước `BE-P2-E05` mở màn trống. |
| Copy l10n | Mọi chuỗi qua `S`, viết tiếng Việt trước. |
