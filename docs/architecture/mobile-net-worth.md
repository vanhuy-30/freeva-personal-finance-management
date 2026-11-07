# Tài sản ròng trên app (MOB-P4-E02)

Màn `/me/net-worth`, mở từ ô "Tài sản ròng" ở lưới Cá nhân. Board Q.1 ([P-investments.md](../brand/patterns/P-investments.md)).

## Hiển thị

- Số hôm nay, dòng thay đổi từ điểm đầu tới điểm cuối của khoảng, biểu đồ đường, chip 7 ngày · 30 ngày · 3 tháng · 6 tháng · 1 năm · Tất cả (mặc định 6 tháng).
- Chạm hoặc kéo trên biểu đồ chọn điểm gần nhất: ngày và số đổi theo điểm đó; đổi khoảng thì trở về điểm mới nhất.
- Dưới 2 điểm thì ẩn biểu đồ (vẫn hiện số).
- Thẻ Tài sản · Nợ, nhóm "Trong tài sản" gồm Ví và Đầu tư theo điểm đang xem.
- Ẩn số dư thì các số hiện `••••••`; biểu đồ vẫn vẽ, nhãn trợ năng không đọc số.

## Dữ liệu

- `GET /reports/net-worth/history?window=` lấy dòng của tiền tệ mặc định (`displayCurrency ?? currency`) trong `items`; bucket không có dòng đó tính 0. Không quy đổi tiền tệ.
- `GET /reports/investments/history?window=` cho phần Đầu tư; Ví = Tài sản − Đầu tư (gồm cả tiền cho mượn). Nếu lệnh này lỗi thì ẩn nhóm "Trong tài sản", biểu đồ vẫn hiện.
- Tiền là chuỗi số nguyên (`BigInt`); JSON number bị từ chối.

## Mã

`apps/mobile/lib/features/net_worth/` (data, domain, presentation) theo mẫu Forecast. Biểu đồ vẽ tay bằng `CustomPainter`; `NetWorthGeometry` dùng chung cho vẽ và chạm.

## Test

Repository, use case, ViewModel, widget (chạm điểm, dưới 2 điểm), golden sáng/tối (`net_worth_*.png`); golden Cá nhân cập nhật vì thêm ô. Đối chiếu board ↔ golden: `tool/design_compare` (nhóm `Q`).

## Chưa có

- Ô "Tài sản ròng" chưa hiện số (chỉ tên) để màn Cá nhân không phải tải thêm dữ liệu.
- Dòng Đầu tư chưa chạm được tới màn đầu tư (`MOB-P4-E01`); dòng Ví chưa mở danh sách ví.
