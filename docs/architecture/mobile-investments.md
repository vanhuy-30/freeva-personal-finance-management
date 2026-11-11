# Đầu tư trên app (MOB-P4-E01)

Task lớn, chia 5 PR nối tiếp (PR 3 hẹp lại, tiền gửi tách ra). Cả 5 PR xong 2026-11-07. Đối chiếu board ↔ golden: `tool/design_compare` nhóm `P` (và `Q`).

| PR | Nội dung | Trạng thái |
|---|---|---|
| 1 | Nền và đọc: giao dịch `investment`, danh sách P.1 + P.2, ô lưới, link từ Tài sản ròng | xong |
| 2 | Tạo khoản đầu tư (P.5, P.6), số lượng thập phân | xong |
| 3 | Danh mục và tài sản (P.3), bán (P.9), cập nhật giá (P.10), mua thêm | xong |
| 4 | Tiền gửi: chi tiết (P.11), rút (P.12), sửa, xoá | xong |
| 5 | Chi tiết, sửa, xoá lần mua (P.4, P.7, P.8), `pairs.py` nhóm `P` | xong |

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

## PR 3 — danh mục, bán, cập nhật giá

- Màn `/me/investments/kind/:kind` (P.3), mở khi chạm thẻ danh mục ở P.2 (trừ Tiền gửi): thẻ tổng danh mục (giá trị, %, số lượng khi cùng một đơn vị, Vốn, Lãi/lỗ), mỗi tài sản một thẻ với pill giá (`8.000.000/chỉ · 05/11` hoặc "Chưa có giá" + "Cập nhật giá"), Giá trị · Vốn · Lãi/lỗ, "Các lần mua" (ô ngày, "có sẵn" màu vàng cho lần mua không trừ ví, "Giá vốn" thay "Giá"), nút Mua thêm · Bán, và dòng "Đã bán" cộng từ các lần bán (`GET /investments/{id}/trades`).
- Bán (P.9, sheet): số lượng, giá bán một đơn vị điền sẵn bằng giá hiện tại, "Bán hết", ngày, ví nhận (không có "đã có từ trước"). Xem trước "Lãi chốt" = tiền nhận − giá vốn phần bán (`soldCostMinor`: theo tỷ lệ, half up, bán hết thì lấy hết giá vốn, giống API). Gửi `POST /investments/{id}/trades` (`side: sell`); số bán vượt số giữ bị chặn trước khi gọi, 422 hiện thông báo riêng.
- Cập nhật giá (P.10, sheet): giá một đơn vị (được là 0), ngày báo giá (hôm nay lấy giờ hiện tại, ngày khác lấy 12:00 để không rơi vào tương lai), hiện "Giá trước". Gửi `POST /investments/{id}/prices`. Không áp dụng cho tiền gửi.
- Mua thêm: mở form tạo (P.5) với danh mục, tên và đơn vị điền sẵn; server gộp lần mua cùng tên vào tài sản đó nên không cần API mới. Bất động sản (một lô) không có Mua thêm.
- Sau mỗi lần ghi: tải lại danh sách, tổng, lần mua của tài sản đó và (khi bán) ví.

## PR 4 — tiền gửi

- Màn `/me/investments/:id` (P.11): "Giá trị hôm nay", % lãi, Gốc và Lãi tạm tính, Lãi suất (`6,5%/năm`, đổi từ bps bằng số nguyên), Ngày gửi, Đáo hạn (`01/06/2027 · còn 223 ngày`, hoặc "đã đáo hạn"), Lấy từ ví (hoặc "Đã có từ trước").
- Rút tiền gửi (P.12, sheet): tiền nhận về điền sẵn bằng giá trị hôm nay (sửa được), ngày rút, ví nhận. Gửi `POST /investments/{id}/trades` bán số lượng 1 với `amountMinor`; một lần rút luôn lấy cả khoản.
- Sửa khoản (sheet): tên, ngày đáo hạn (phải sau ngày gửi), ghi chú, `PATCH /investments/{id}` kèm `version`.
- Xoá khoản: xác nhận rồi xoá lần mua duy nhất (`DELETE …/trades/{id}?version=`); server trả 204 khi đó là lần cuối nên khoản biến mất, tiền gốc về ví. Tải lại ví và danh sách.
- Chạm thẻ Tiền gửi ở P.2: một khoản thì mở thẳng chi tiết, nhiều khoản thì mở màn danh mục (mỗi khoản một dòng mở chi tiết, không có giá, Mua thêm, Bán).

## PR 5 — chi tiết, sửa, xoá lần mua

- Chạm một lần mua ở màn danh mục mở `/me/investments/:id/trades/:tradeId` (P.4): giá trị hiện tại của lần mua (số lượng × giá hiện tại), %, Vốn, Lãi/lỗ; các dòng Ngày mua, Số lượng, Giá mua, Lấy từ ví (hoặc "Đã có từ trước"), Giá hiện tại (chạm mở "Cập nhật giá"), Ghi chú. Nút Sửa và Xoá.
- Sửa (P.7, `…/edit`): số lượng, giá một đơn vị, ngày, "Tổng tiền" tự tính, ví (đổi được sang "Đã có từ trước", bỏ chân ví), ghi chú; bất động sản chỉ có ô giá mua. Gửi `PATCH /investments/{id}/trades/{tradeId}` kèm `version`; server phát lại vị thế nên giá vốn và lãi các lần bán sau tự tính lại.
- Xoá (P.8, sheet): "Xoá lần mua 10/09?", dòng "Trả lại <ví> +35.000.000" (không có khi "đã có từ trước"), Xoá lần mua · Giữ lại. `DELETE …/trades/{id}?version=`: xoá lần cuối thì tài sản mất theo (204), nên về danh sách thay vì danh mục.
- Số đã bán vượt số còn lại (422) hiện thông báo riêng, không đổi gì.

## Chưa có

- Footer "Đã bán hết" ở P.2 (tài sản đã bán hết, số lượng 0) và xem lại/sửa/xoá từng lần bán (thiết kế không có sửa lần bán; API cũng không cho).
- Tiền gửi: thêm tiền gửi vào khoản đang có (API không hỗ trợ).
