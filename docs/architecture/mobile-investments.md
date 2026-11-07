# Đầu tư trên app (MOB-P4-E01)

Task lớn, chia 4 PR nối tiếp. Tài liệu này theo dõi phần đã có.

| PR | Nội dung | Trạng thái |
|---|---|---|
| 1 | Nền và đọc: giao dịch `investment`, danh sách P.1 + P.2, ô lưới, link từ Tài sản ròng | xong |
| 2 | Tạo khoản đầu tư (P.5, P.6), số lượng thập phân | xong |
| 3 | Danh mục và tài sản (P.3), bán (P.9), cập nhật giá (P.10), mua thêm, tiền gửi (P.11, P.12) | chưa |
| 4 | Chi tiết, sửa, xoá lần mua (P.4, P.7, P.8), `pairs.py` nhóm `P` | chưa |

## PR 1

- Màn `/me/investments`, mở từ ô "Đầu tư" ở lưới Cá nhân và từ dòng "Đầu tư" ở màn Tài sản ròng.
- Thẻ tổng (A2): giá trị, `▲/▼ %`, Vốn, Lãi/lỗ dự kiến; đường mờ là lịch sử 6 tháng từ `/reports/investments/history`, ẩn khi dưới 2 điểm hoặc lệnh lỗi.
- Thẻ tỷ trọng (vòng + chú giải) và thẻ từng danh mục (Giá trị · Vốn · Lãi/lỗ). Khoản chưa có giá hiện tag "Chưa có giá" và `—`.
- Dữ liệu: `GET /investments` và `/investments/summary`; chọn tiền tệ mặc định, không quy đổi. Tiền và bps là chuỗi (`BigInt`, `int`); JSON number bị từ chối. Phần trăm hiển thị bằng số nguyên (làm tròn half away from zero, một chữ số thập phân).
- `TransactionType.investment`: chân ví một chiều của mua/bán, hiện trong danh sách giao dịch là "Đầu tư", khoá sửa/xoá (như `debt`), không tính vào thu/chi.
- Mã lỗi mới `investmentOversell`, `investmentUnsupported` (ánh xạ từ 422) để các PR sau dùng.

## PR 2 — tạo khoản đầu tư

- Màn `/me/investments/new` (`?kind=` chọn sẵn danh mục): chip sáu danh mục, tên, vàng chọn chỉ/lượng, số lượng, giá một đơn vị, ngày mua, "Tổng tiền" tự tính, "Lấy từ ví" (radio, có "Đã có từ trước · Không trừ ví"), ghi chú. Tiền gửi: số tiền gửi, lãi suất/năm, ngày gửi, ngày đáo hạn. Bất động sản: một ô "Giá mua", số lượng cố định 1.
- Mở từ nút + ở P.2 và từ ba chip + nút "Thêm khoản đầu tư" ở P.1.
- Gửi `POST /investments` kèm `initialTrade` một lần; `clientId` giữ suốt màn nên gửi lại không ghi hai lần; trùng tên thì server gộp lần mua vào tài sản cũ. Gửi `priceMinor` (giá người dùng gõ), tiền gửi và bất động sản gửi `amountMinor`.
- `core/money/quantity.dart`: số lượng là `BigInt` nhân 10^8 (crypto tới 8 chữ số), tổng = làm tròn half up, không dùng double. Lãi suất gõ `5,8` thành 580 bps.
- Ví nguồn quyết định tiền tệ của khoản; "đã có từ trước" dùng tiền tệ hồ sơ. Mua từ ví tải lại ví.

## Chưa có sau PR 2

- Chạm thẻ danh mục chưa mở P.3; footer "Đã bán hết" chưa có.
