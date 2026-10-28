# Nhóm F — Báo cáo

Trạng thái: **chốt thiết kế 2026-10-21**, đã code 2026-10-23 (F1 + F2). Task: `DS-P2-003` (màn Báo cáo); ngân sách thuộc `BE-P2-E02` / `MOB-P2-E02`.
Canvas: trang **05 · Patterns**, hàng F
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Báo cáo là màn gốc của tab (có bottom nav). Chi tiết danh mục là màn tiếp theo (không bottom nav). Chọn khoảng ngày là popup.
- Trả lời đủ câu hỏi người dùng tài chính hay hỏi: thu/chi bao nhiêu, trung bình mỗi ngày, còn bao nhiêu ngân sách, xu hướng ra sao, tiền đi đâu.
- So sánh không phán xét: "↓ 6% so với T9" màu xám; trạng thái ngân sách nói về nhịp chi ("Đúng nhịp"), không khen chê.
- Màu dữ liệu theo thứ tự cố định `data.1 → data.2 → data.3 → data.4 (Khác)`; từ nhóm thứ 4 trở đi gộp "Khác". Số rút gọn (9,32tr) chỉ trong biểu đồ.
- Thu/chi không quy đổi giữa các tiền tệ (như [B-overview.md](B-overview.md)).

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Báo cáo (tháng) | "Báo cáo". Kỳ: **Tuần · Tháng · Năm · Tuỳ chọn**. "‹ Tháng 10, 2026 ›" + "01/10 – 31/10" (› khoá ở kỳ hiện tại). **Thẻ tổng:** Thu, Chi (+ so với kỳ trước), **Chi trung bình/ngày**, Còn lại. **Ngân sách tháng:** % đã dùng trên hạn mức, thanh + vạch "Hôm nay ở 68% tháng", chip nhịp, ô **Còn lại** và **Mỗi ngày tiêu được**. **Xu hướng chi:** biểu đồ cột Tuần/Tháng/Năm, kỳ hiện tại tô primary, đường nét đứt ngân sách, "Trung bình 6 tháng". **Phân tích:** Chi · Thu · Ví; Chi/Thu là biểu đồ tròn + danh sách số tiền theo danh mục | Màn cuộn dài |
| 2 | Theo ví | Như 1, phần phân tích ở "Ví": mỗi ví "Vào +… · Ra −…" và số ròng; tổng ròng các ví = Còn lại | Chạm mở chi tiết ví (nhóm D) |
| 3 | Một danh mục trong kỳ | Quay lại · "Ăn uống" · "Tháng 10, 2026". Tổng, "% tổng chi · N giao dịch". Thanh theo danh mục con (kể cả "(chung)"). "Giao dịch lớn nhất" 3 dòng + "Xem cả N" (mở danh sách giao dịch đã lọc) | |
| 4 | Khoảng tuỳ chọn (popup) | Chip "7 ngày qua · 30 ngày qua · Quý này". Lịch tháng, tuần bắt đầu thứ Hai; khoảng chọn nền `tint.blue`, hai đầu nền primary; hôm nay có viền; ngày tương lai khoá. "06/10 – 19/10 · 14 ngày". "Huỷ" · "Xem khoảng này" | Tối đa 3660 ngày (giới hạn API) |
| 5 | Kỳ chưa có số liệu | Minh hoạ ba nét F, "Chưa có số liệu tháng 3", nút "Về tháng này" | |

## Quy tắc số liệu

| Chỉ số | Cách tính |
|---|---|
| Chi trung bình/ngày | Tổng chi ÷ số ngày đã qua của kỳ (kỳ đang chạy) hoặc số ngày của kỳ (kỳ đã hết) |
| So với kỳ trước | (Chi kỳ này − chi kỳ trước) ÷ chi kỳ trước, làm tròn %; mũi tên lên/xuống, màu xám |
| Ngân sách đã dùng | Chi (không tính chuyển ví) ÷ hạn mức tháng |
| Nhịp | So % đã dùng với % thời gian đã qua: ≤ → "Đúng nhịp" (`status.success`); vượt tới 10 điểm → "Hơi nhanh" (`status.warning`); vượt hơn hoặc quá 100% → "Vượt ngân sách" (`status.danger`) |
| Mỗi ngày tiêu được | Còn lại ÷ số ngày còn lại của kỳ; âm thì ẩn ô này |
| Xu hướng | Tuần: 8 tuần · Tháng: 6 tháng · Năm: các năm có dữ liệu (tối đa 5) |

## Thành phần mới (bổ sung vào design system)

- **Điều hướng kỳ:** hai nút tròn 40 hai bên, tên kỳ `titleL` + khoảng ngày `label`; nút sau khoá ở kỳ hiện tại.
- **Thẻ ngân sách:** % lớn, thanh 10 có vạch "hôm nay", chip nhịp, hai ô số liệu nền `bg.subtle`.
- **Biểu đồ cột xu hướng:** cột 26 bo trên 8; kỳ hiện tại `data.1`, kỳ khác `data.muted`; nhãn giá trị rút gọn trên cột; đường ngân sách nét đứt `ink.400`; có nhãn trợ năng đọc đủ số.
- **Biểu đồ tròn phân bổ:** vòng 16, tổng rút gọn ở giữa, chú thích % bên phải.
- **Popup chọn khoảng ngày:** chip nhanh, lịch 7 cột, tô khoảng, dòng tóm tắt số ngày.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Ngân sách | `BE-P2-E02` / `MOB-P2-E02`. Chưa có ngân sách thì thay khối bằng một dòng "Đặt ngân sách tháng" (mở form ngân sách). |
| Xu hướng | Cần API chuỗi số chi theo tuần/tháng/năm (một lần gọi), không gọi lặp từng kỳ. |
| Kỳ Năm | API hiện có tuần, tháng, khoảng; thêm `year` hoặc dùng khoảng 01/01–31/12 theo múi giờ hồ sơ. |
| So với kỳ trước | Gọi thêm kỳ trước, hoặc API trả sẵn. |
| Giao dịch lớn nhất | API danh sách giao dịch cần sắp xếp theo số tiền và lọc theo danh mục + khoảng ngày. |
| Ngày bắt đầu kỳ | Kỳ tháng theo `fiscalMonthStartDay`; nhãn kỳ đổi thành khoảng ngày khi ngày bắt đầu ≠ 1. |
| Copy l10n | Thay `reportInvalid` dài bằng thông báo ngắn; "Chuyển khoản" → "Chuyển ví" theo thuật ngữ. |
