# Nhóm C — Giao dịch

Trạng thái: **chốt thiết kế 2026-10-21**. **C1 đã code 2026-10-22**, C2 đang làm. Task: `DS-P2-005`.
Canvas: trang **05 · Patterns**, hai hàng C1 và C2
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Màn danh sách theo loại **Danh sách**; ghi/sửa theo loại **Nhập liệu**; chi tiết, bộ lọc, chọn danh mục, chọn nhãn là **sheet**.
- **Tên dòng giao dịch:** cửa hàng nếu có, không thì tên danh mục. Dòng phụ: danh mục · ví (hoặc ví · ghi chú khi tên đã là danh mục).
- Chi màu ink + dấu −, thu `money.income` + dấu +, chuyển ví màu muted không dấu. Không tô đỏ khoản chi.
- Xoá là xoá mềm: không hỏi lại, luôn có toast **Hoàn tác** và mục **Đã xoá** để khôi phục.
- Màu giữ theo spec hiện tại (đã thử ba mức tăng màu, product owner chọn giữ nguyên).

## C1 · Xem, tìm, lọc

```
Danh sách → Tìm kiếm
          → Bộ lọc (sheet) → Danh mục / Nhãn (sheet) · Đã xoá
          → Chi tiết (sheet) → Sửa · Sao chép · Xoá → Danh sách + toast Hoàn tác
```

| # | Màn | Nội dung | Thành phần |
|---|---|---|---|
| 1 | Danh sách | "Giao dịch" + nút tìm, nút lọc. Chip: Tất cả · Chi · Thu · Chuyển · Tháng 10 ▾. Dòng tổng "Thu +… Chi −…" của bộ lọc. Nhóm theo ngày ("Hôm nay · 21/10") kèm tổng ròng | Thẻ list trắng, dòng giao dịch 56+, bottom nav |
| 2 | Tìm kiếm | Ô tìm focus sẵn, nút xoá chữ, "Huỷ". Chip lọc vẫn hiện, kỳ mặc định "Mọi lúc". "3 kết quả · Chi −185.000". Phần khớp tô nền `tint.blue` | Tìm không dấu ("pho" ra "Phở"), khớp cả ghi chú; cập nhật sau 300 ms |
| 3 | Bộ lọc (sheet) | "Bộ lọc" + "Đặt lại". Thời gian: Tuần này · Tháng này · Tháng trước · Tuỳ chọn. Ví: chip chọn nhiều. Danh mục, Nhãn: ô chọn mở sheet. Dòng "Đã xoá" kèm số lượng. Nút "Xem 24 giao dịch" | Chip chọn viền ink 1.5; nút primary ghi số kết quả |
| 4 | Không có kết quả | Bộ lọc đang bật hiện thành chip ink có ×, chấm xanh trên nút lọc. Minh hoạ ba nét F (khung tĩnh của animation trống), "Không có giao dịch phù hợp" · "Thử bỏ bớt bộ lọc." · nút "Xoá bộ lọc" | Trạng thái trống |
| 5 | Chi tiết (sheet) | Icon danh mục, tên, số tiền `moneyL`. Thẻ: Danh mục · Ví · Thời gian · Nhãn (chip violet) · Ghi chú. Đáy: Xoá (nút icon viền đỏ) · Sao chép (secondary) · Sửa (ink) | Sửa mở form C2.3 với tiêu đề "Sửa khoản chi" và nút "Lưu thay đổi". Sao chép mở form Ghi chi đã điền sẵn, ngày = hôm nay |
| 6 | Sau khi xoá | Dòng biến mất, tổng ngày và tổng tháng cập nhật. Toast ink "Đã xoá khoản chi · Hoàn tác", 6 s | Toast trên bottom nav |
| 7 | Đã xoá | Màn đẩy vào: "Đã xoá" · "Khôi phục để đưa giao dịch về danh sách." Nhóm theo ngày giao dịch, số tiền muted, nút khôi phục tròn ở cuối dòng | Không có "xoá vĩnh viễn" hay "tự xoá sau N ngày" (Phase 1 chưa có) |

## C2 · Ghi chi, chuyển ví

```
Nút + → Ghi chi → Tất cả danh mục (sheet)
              → Ghi chú, cửa hàng, nhãn → Nhãn (sheet)
              → Lưu → Danh sách + toast Hoàn tác
      → Chuyển (segmented) → Chuyển ví
```

| # | Màn | Nội dung | Thành phần |
|---|---|---|---|
| 1 | Ghi chi | Segmented Chi · Thu · Chuyển. Số tiền 52 focus sẵn. Chip 3 danh mục hay dùng + "Tất cả". Ô Ví (gần nhất), Ngày (hôm nay). Nút nét đứt "Ghi chú, cửa hàng, nhãn". Bàn phím số có `000`. "Lưu khoản chi" | Ghi thu: cùng màn, nút "Lưu khoản thu" |
| 2 | Chọn danh mục (sheet) | "Chọn danh mục", ô tìm. "Hay dùng": 4 thẻ chọn, thẻ đang chọn nền `tint.blue` viền primary có dấu tích. "Tất cả": dòng danh mục cha (icon hai tông) + chip danh mục con thụt lề | Chọn cha hoặc con đều được; chọn xong đóng sheet |
| 3 | Ghi chú, cửa hàng, nhãn | Ẩn bàn phím số; số tiền thu về 40, chạm để sửa. Thẻ: Danh mục · Ví · Thời gian (có giờ). Trường "Cửa hàng", "Ghi chú" (nhãn trong ô). Nhãn: chip violet có × và "+ Thêm nhãn" | Cũng là màn Sửa |
| 4 | Nhãn (sheet) | "Nhãn" + "Xong". Ô "Tìm hoặc tạo nhãn". Dòng đầu "Tạo nhãn “Du lịch”" khi chưa có, rồi các nhãn khớp dạng checkbox. Mục "Đã chọn" | Đủ 20 nhãn trên một giao dịch: dòng tạo/checkbox còn lại bị khoá, chữ "Tối đa 20 nhãn" ngay dưới ô tìm. Không hiện giới hạn trước đó |
| 5 | Chuyển ví | Segmented ở "Chuyển". "Số tiền chuyển" theo tiền tệ ví nguồn. Thẻ Từ / Đến với nút đảo chiều. Khác tiền tệ: thẻ tỷ giá "Tỷ giá lúc 09:30, 21/10 · 1 USD = 25.380 ₫" (sửa được) và "Nhận được 100,00 USD". "Lưu chuyển ví" | Cùng tiền tệ: ẩn thẻ tỷ giá. Lưu rate + thời điểm; hai leg cân bằng |
| 6 | Đã lưu | Về danh sách, dòng mới tô nền `tint.blue` rồi mờ dần. Toast "Đã lưu khoản chi · Hoàn tác" | |

## Thành phần mới (bổ sung vào design system)

- **Sheet bộ lọc:** tay nắm, tiêu đề + "Đặt lại", nhóm chip chọn, ô chọn mở sheet con, nút primary ghi số kết quả.
- **Chip bộ lọc đang bật:** nền ink, chữ trắng, nút × 16; chạm × bỏ riêng điều kiện đó. Nút lọc có chấm primary khi có điều kiện.
- **Dòng giao dịch đã xoá:** số tiền `money.transfer`, icon nền subtle, nút khôi phục tròn 40 viền `border.default`, icon primary.
- **Dòng tạo nhanh:** chữ primary, ô vuông `tint.blue` có dấu +; dùng cho nhãn (sau này dùng cho danh mục).
- **Chip nhãn:** nền `tint.violet`, chữ `tint.violetFg`, cao 28 (đọc) / 36 (sửa, có ×).
- **Thẻ ví Từ / Đến:** hai dòng 60 trong một thẻ, nút đảo chiều 40 nằm trên đường chia.
- **Thẻ tỷ giá:** dòng "Tỷ giá lúc …" + giá trị, icon bút primary; dòng "Nhận được".

## Trạng thái code

| Việc | Đã làm / còn chờ |
|---|---|
| C1.1–C1.7 | Đã làm: danh sách (chip, tổng theo bộ lọc, nhóm theo ngày), tìm kiếm (`/transactions/search`), sheet bộ lọc, không kết quả, sheet chi tiết (Sửa · Sao chép · Xoá + Hoàn tác), Đã xoá (`/transactions/deleted`). |
| API lọc | `GET /transactions` nhận `accountId`, `categoryId`, `tagId` lặp lại; tìm khớp `merchant`; trả `summary` (số giao dịch, thu/chi theo tiền tệ) cho cả kết quả lọc. |
| Danh mục cha | Chọn cha thì app tự gồm danh mục con khi gửi bộ lọc. |
| Khoảng tuỳ chọn | Tạm dùng bộ chọn khoảng ngày của hệ thống; sheet chọn ngày của Freeva làm cùng C2. |
| Giờ giao dịch | Chỉ có ngày; giờ tách thành `BE-P2-E09 / MOB-P2-E09`. Chi tiết hiện "Hôm nay · 21/10". |
| C2 | Đang làm (PR thứ hai). |

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Lọc nhiều ví / nhiều danh mục | API `GET /transactions` hiện nhận một `accountId`, một `categoryId`; cần mảng. |
| Lọc theo nhãn | API chưa có tham số nhãn. |
| Tìm theo cửa hàng | Tìm kiếm hiện khớp ghi chú, tên danh mục, tên ví, tên nhãn và số tiền; chưa khớp `merchant`. |
| Tổng thu/chi theo bộ lọc, số kết quả | Cần API trả tổng theo đúng bộ lọc (không cộng ở client theo trang). |
| Lọc ở mobile | `TransactionQuery` mobile mới có loại, tìm kiếm, đã xoá; thêm ví, danh mục, khoảng ngày. |
| Sao chép giao dịch | Chỉ là mở form điền sẵn; không cần API mới. |
| Copy l10n | Toàn bộ chuỗi trên đi qua `S`, viết tiếng Việt trước. |
