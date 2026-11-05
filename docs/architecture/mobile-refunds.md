# Hoàn tiền trên app — MOB-P3-008

Ghi hoàn tiền cho một khoản chi và xoá khoản chi đã có hoàn tiền. Contract: [refunds.md](refunds.md). Thiết kế: [patterns/M-wallet-refund-installment.md](../brand/patterns/M-wallet-refund-installment.md) màn 2–4, board `TxDetail3`, `TxRefund`, `TxRefundDelete`.

## Hành vi

- **Chi tiết khoản chi** (sheet chi tiết giao dịch): dòng "Đã hoàn +…" khi `refundedMinor` > 0; card "Ghi hoàn tiền · Đổi trả, hoàn một phần" khi khoản chi chưa xoá và còn hoàn được (số tiền − `refundedMinor` > 0) và user ghi được. Hàng "Chuyển thành trả góp" của board để `MOB-P3-009`.
- **Sheet "Hoàn tiền {tên}"**: "Đã chi {số} · dd/MM", ô "Số tiền hoàn", chip "Hoàn toàn bộ {phần còn lại}", "Vào ví" (mặc định ví đã chi; chỉ ví chưa ẩn cùng tiền tệ, API không nhận ví khác tiền tệ), "Ngày" (mặc định hôm nay), gợi ý "Trừ vào chi {danh mục} tháng {M của khoản chi}, không tính là thu." Số lớn hơn phần còn lại thì nút tắt và gợi ý thành chữ đỏ; server trả `REFUND_EXCEEDS_ORIGINAL` cũng báo như vậy. `clientId` giữ suốt sheet nên bấm lại không ghi hai lần. Chỉ online (không xếp hàng sync).
- **Xoá khoản chi có hoàn tiền**: popup "Xoá khoản chi này?" với hai thẻ radio "Xoá cả hoàn tiền · Ví bớt đi {số}" (mặc định, `refunds=cascade`) và "Giữ hoàn tiền · Chuyển thành một khoản thu" (`keep`). Mở khi `refundedMinor` > 0, hoặc khi xoá thường nhận `409 REFUND_EXISTS` (dữ liệu cũ: đọc lại khoản chi lấy số và version mới). Không có "Hoàn tác" vì khôi phục khoản chi không khôi phục hoàn tiền đã xoá; mất mạng thì báo lỗi, không xếp hàng.
- **Giao dịch `refund`**: dòng "Hoàn tiền" (icon hoàn, tông thu, dấu +), dòng phụ "{danh mục} · {ví}"; chi tiết có "Hoàn cho {tên khoản chi}" (lấy từ danh sách đang tải, không có thì `GET /transactions/{id}`), chạm mở chi tiết khoản chi; chỉ có nút Xoá (owner chốt 2026-11-05). Bộ lọc loại có nhãn "Hoàn tiền".
- Danh sách giao dịch: khoản chi có hoàn tiền ghi "{phần đầu dòng phụ} · đã hoàn {số}".
- Loại giao dịch app chưa biết (server mới hơn) bị bỏ qua khi đọc danh sách thay vì làm hỏng cả trang.

## Layer

`TransactionType.refund`, `RefundDisposition`, `RefundCommand`, `TxLeg.refundOfId` / `refundedMinor`, `TransactionBundle.refunded` / `refundable` ở domain. `TransactionRepository.refund` (`POST /transactions/{id}/refunds`, `Idempotency-Key` = `clientId`) và `remove(…, refunds:)`. `AuthError.refundExists` / `refundExceeds` map từ mã lỗi 409. ViewModel `refund(...)` theo khuôn `adjust()`. Tiền là `BigInt`.

## Khác biệt có chủ ý so với board

- Sheet và popup mở trên danh sách giao dịch (board vẽ trên chi tiết thẻ có trả góp).
- Dòng phụ khoản chi chỉ giữ phần đầu ("Mua sắm") để "đã hoàn …" vừa một dòng.
- Nút Xoá của giao dịch hoàn tiền là nút rộng viền đỏ (board chưa vẽ màn này).

## Test

`test/features/transactions/refund_test.dart` (đọc `refund`/`refundedMinor`, bỏ loại lạ, request hoàn tiền và xoá, trần hoàn tiền), `refund_golden_test.dart` (golden sáng/tối + 1.3×, chip điền phần còn lại, popup gửi đúng lựa chọn, giao dịch hoàn tiền chỉ có Xoá). Đối chiếu board ↔ golden: `apps/mobile/tool/design_compare` nhóm `M`.
