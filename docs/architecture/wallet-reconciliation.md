# Đối soát số dư ví — BE-P3-005 / MOB-P3-005

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `POST /api/v1/financial-accounts/{id}/reconcile`. Phần mobile (`MOB-P3-005`) làm riêng.

## Chức năng

User nhập số dư thật của ví. API trả chênh lệch và, nếu khác 0, tạo một giao dịch `adjustment` một leg để số dư ví bằng số đã nhập. Cần khi app lệch tiền thật vì sót giao dịch mà không muốn bịa thu/chi.

## Mô hình

- `TransactionType` thêm `adjustment` (migration `20261102300000_transaction_adjustment`, additive; deploy trước API).
- Một dòng `Transaction`, một leg, `amountMinor` có dấu (dương tăng ví, âm giảm ví), không `categoryId`, `merchant`, FX. Không tạo qua `POST /transactions` (chỉ qua reconcile).
- Số dư ví đã là `initial + SUM(amountMinor)` mọi loại, nên adjustment tự cập nhật số dư và tài sản ròng.

## API

Body: `clientId` (= `Idempotency-Key`), `actualBalanceMinor`, tuỳ chọn `occurredOn` (mặc định hôm nay theo múi giờ hồ sơ), `notes`, `dryRun`.

- `delta = target - số dư hiện tại`. Ví thẻ tín dụng đối soát theo **dư nợ**: user nhập số nợ, `target = -nợ`.
- `delta = 0` hoặc `dryRun: true`: không ghi, trả `currentBalanceMinor`, `targetBalanceMinor`, `deltaMinor`, `transaction: null` (app dùng `dryRun` để hiện chênh lệch trước khi xác nhận).
- Retry cùng `clientId` trả lại adjustment đã lưu (200), không tính lại theo số dư mới. `clientId` đã dùng cho giao dịch khác hoặc ví khác → 409.
- Ví lưu trữ → 409. Ví của owner khác → 404.

Sửa và xóa adjustment qua `PATCH`/`DELETE /transactions/{id}` như giao dịch thường (version). `PATCH` không được gán danh mục hoặc FX (400).

## Không tính vào đâu

| Nơi | Cách xử lý |
|---|---|
| Thu/chi kỳ, tỷ lệ tiết kiệm, tháng review, series | Các truy vấn lọc `income`/`expense` nên bỏ qua adjustment |
| Ngân sách, thông báo ngưỡng | Chỉ đếm `expense` |
| Báo cáo theo ví | Field riêng `adjustmentMinor`, cộng vào `netMinor` của ví |
| `GET /transactions` | Có trong danh sách, lọc `type=adjustment`; `summary.totals[].adjustmentMinor` tách riêng |
| Định kỳ | Không tạo được rule `adjustment` |
| Sync (gợi ý trùng) | Bỏ adjustment khỏi ứng viên trùng |
| Export / xóa tài khoản | Có trong export (`type: adjustment`), xóa cùng tài khoản |

## Test

Unit: [reconcile.spec.ts](../../backend/api/src/modules/transactions/reconcile.spec.ts) (delta ví thường và thẻ, bigint trên 2^53, validate). PostgreSQL: [reconcile.integration-spec.ts](../../backend/api/test/reconcile.integration-spec.ts) (số dư, replay, dry run, thẻ theo dư nợ, báo cáo không đổi, sửa/xóa, owner khác).

**Tồn đọng:** `MOB-P3-005` (nhập số dư thực tế trên chi tiết ví) chưa làm; chưa deploy staging.
