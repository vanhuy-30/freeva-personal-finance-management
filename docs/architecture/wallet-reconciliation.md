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

## Mobile (`MOB-P3-005`, 2026-11-04)

- Lối vào: link "Khớp số dư" dưới thẻ số dư trên chi tiết ví/thẻ ([reconcile_sheet.dart](../../apps/mobile/lib/features/wallets/presentation/widgets/reconcile_sheet.dart)); ví đã ẩn không có link (server trả 409).
- Mọi số trong sheet do server trả (`currentBalanceMinor`, `deltaMinor`); app chỉ lấy "số gõ − số đang hiện" để đọc chênh lệch (ví thẻ: theo dư nợ). Gõ xong 300 ms thì gọi `dryRun`, bấm nút mới ghi.
- `clientId` đổi khi số gõ đổi, giữ nguyên khi thử lại.
- `TransactionType.adjustment` có trong app: hiện trong lịch sử; chi tiết cho Sửa số tiền (sheet riêng, `PATCH /transactions/{id}` chỉ gửi leg mới, không danh mục/FX, không qua hàng đợi offline) và Xoá, không Sao chép.
- Ví thường nhập được số âm (ví đang âm); ví thẻ chỉ nhập dư nợ ≥ 0.

**Tồn đọng:** sửa điều chỉnh khi offline; chưa deploy staging; chưa chạy trên thiết bị thật.
