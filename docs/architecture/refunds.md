# Hoàn tiền gắn khoản chi gốc — BE-P3-008 / MOB-P3-008

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `POST /api/v1/transactions/{id}/refunds`. Phần mobile (`MOB-P3-008`) làm riêng.

## Chức năng

Từ một khoản chi, user ghi hoàn tiền (một phần hoặc toàn bộ) vào một ví. Hoàn tiền không phải thu nhập: báo cáo và ngân sách trừ nó khỏi chi của đúng danh mục và đúng kỳ của khoản chi gốc, dù hoàn tiền về sau (ví dụ chi tháng 10, hoàn tháng 11 thì tháng 10 giảm).

## Mô hình

- `TransactionType` thêm `refund`; `Transaction.refundOfId` trỏ khoản chi gốc (migration `20261103100000_transaction_refund`, additive; deploy trước API).
- Một dòng, một leg, `amountMinor` dương vào ví nhận, `categoryId` sao từ khoản gốc, không merchant/FX/nhãn. Ví nhận phải cùng tiền tệ với khoản gốc (khác thì 400), có thể là ví khác ví đã chi.
- Chỉ tạo qua endpoint riêng, không qua `POST /transactions`.
- Số dư ví đã là `initial + SUM(amountMinor)` mọi loại, nên hoàn tiền tự cập nhật số dư và tài sản ròng.

## API

Body: `clientId` (= `Idempotency-Key`), `accountId`, `amountMinor` (> 0), tuỳ chọn `occurredOn` (mặc định hôm nay theo múi giờ hồ sơ), `notes`.

- Khoản gốc phải là `expense` chưa xóa của owner (không thì 409; owner khác 404).
- Tổng hoàn chưa xóa ≤ số tiền gốc, kiểm tra trong cùng transaction và khóa dòng gốc nên hai request song song không vượt; vượt thì `409 REFUND_EXCEEDS_ORIGINAL`.
- Retry cùng `clientId` trả lại hoàn tiền đã lưu (200); cùng `clientId` khác dữ liệu → 409.
- Sửa/xóa hoàn tiền qua `PATCH`/`DELETE /transactions/{id}` (version). Sửa số tiền hoặc khôi phục vẫn bị chặn bởi tổng hoàn; không gán danh mục/merchant/FX/nhãn (400).
- Sửa khoản gốc: không hạ số tiền dưới tổng hoàn (409), không đổi tiền tệ khi đã có hoàn tiền (400), đổi danh mục thì hoàn tiền đổi theo.

## Xóa khoản gốc

Khoản chi còn hoàn tiền: `DELETE /transactions/{id}?version=…` trả `409 REFUND_EXISTS`. App hỏi user rồi gửi lại với `refunds`:

| `refunds` | Kết quả |
|---|---|
| `cascade` | Xóa mềm cả hoàn tiền; ví mất khoản tiền đó. |
| `keep` | Hoàn tiền thành thu nhập thường (`income`, không danh mục); số dư ví không đổi. |

Cùng tham số này có trên `PATCH` với `deleted: true`. Khôi phục khoản gốc không khôi phục hoàn tiền đã xóa kèm.

## Nơi tính hoàn tiền

| Nơi | Cách xử lý |
|---|---|
| Báo cáo dòng tiền, theo danh mục, merchant, series, review tháng | Hoàn tiền tính như chi âm theo ngày/danh mục/merchant của khoản gốc (`flow` trong `prisma-report.repository.ts`), không đếm thêm giao dịch |
| Tỷ lệ tiết kiệm | Theo chi ròng; không vào thu nhập |
| Ngân sách và thông báo ngưỡng | `periodSpendRows` trừ hoàn tiền của các khoản chi trong kỳ |
| Báo cáo theo ví | Field `refundMinor` (theo ngày hoàn tiền), cộng vào `netMinor` |
| `GET /transactions` | Có trong danh sách, lọc `type=refund`; `summary.totals[].refundMinor` tách riêng; khoản chi có `refundedMinor` (tổng hoàn chưa xoá, `"0"` khi chưa có; `null` với loại khác), cũng có ở `GET /transactions/{id}` |
| Gợi ý trùng khi sync, định kỳ | Bỏ qua refund; rule định kỳ không tạo được refund |
| Export / xóa tài khoản | Có trong export (`type: refund`, `refundOfId`), xóa cùng tài khoản |

## Test

Unit: [refund.spec.ts](../../backend/api/src/modules/transactions/refund.spec.ts) (trần tổng hoàn, bigint trên 2^53, validate leg, trừ ngân sách). PostgreSQL: [refund.integration-spec.ts](../../backend/api/test/refund.integration-spec.ts) (số dư, replay, vượt trần, song song, báo cáo và ngân sách theo kỳ gốc, xóa gốc `cascade`/`keep`, sửa vượt trần).

Mobile: [mobile-refunds.md](mobile-refunds.md) (`MOB-P3-008`).

