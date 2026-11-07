# Đầu tư trên app (MOB-P4-E01)

Task lớn, chia 4 PR nối tiếp. Tài liệu này theo dõi phần đã có.

| PR | Nội dung | Trạng thái |
|---|---|---|
| 1 | Nền và đọc: giao dịch `investment`, danh sách P.1 + P.2, ô lưới, link từ Tài sản ròng | xong |
| 2 | Tạo khoản đầu tư (P.5, P.6), số lượng thập phân | chưa |
| 3 | Danh mục và tài sản (P.3), bán (P.9), cập nhật giá (P.10), mua thêm, tiền gửi (P.11, P.12) | chưa |
| 4 | Chi tiết, sửa, xoá lần mua (P.4, P.7, P.8), `pairs.py` nhóm `P` | chưa |

## PR 1

- Màn `/me/investments`, mở từ ô "Đầu tư" ở lưới Cá nhân và từ dòng "Đầu tư" ở màn Tài sản ròng.
- Thẻ tổng (A2): giá trị, `▲/▼ %`, Vốn, Lãi/lỗ dự kiến; đường mờ là lịch sử 6 tháng từ `/reports/investments/history`, ẩn khi dưới 2 điểm hoặc lệnh lỗi.
- Thẻ tỷ trọng (vòng + chú giải) và thẻ từng danh mục (Giá trị · Vốn · Lãi/lỗ). Khoản chưa có giá hiện tag "Chưa có giá" và `—`.
- Dữ liệu: `GET /investments` và `/investments/summary`; chọn tiền tệ mặc định, không quy đổi. Tiền và bps là chuỗi (`BigInt`, `int`); JSON number bị từ chối. Phần trăm hiển thị bằng số nguyên (làm tròn half away from zero, một chữ số thập phân).
- `TransactionType.investment`: chân ví một chiều của mua/bán, hiện trong danh sách giao dịch là "Đầu tư", khoá sửa/xoá (như `debt`), không tính vào thu/chi.
- Mã lỗi mới `investmentOversell`, `investmentUnsupported` (ánh xạ từ 422) để các PR sau dùng.

## Chưa có ở PR 1

- Chưa thêm được khoản đầu tư: P.1 bỏ ba chip và nút "Thêm khoản đầu tư" cho tới PR 2.
- Chạm thẻ danh mục chưa mở P.3; footer "Đã bán hết" chưa có.
