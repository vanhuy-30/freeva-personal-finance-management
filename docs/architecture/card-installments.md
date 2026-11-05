# Trả góp thẻ tín dụng — BE-P3-009 / MOB-P3-009

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/card-installments`. Module: [03-financial-accounts](../product/modules/03-financial-accounts.md). Phần mobile (`MOB-P3-009`) làm riêng.

## Chức năng

User đổi một khoản chi đã ghi trên ví thẻ tín dụng thành kế hoạch trả góp: số kỳ, số mỗi kỳ, kỳ đầu. Kế hoạch **chỉ là lịch**, không ghi tiền:

- Khoản mua vẫn là một khoản chi đủ số vào ngày mua, tính vào báo cáo và ngân sách tháng mua đúng một lần; dư nợ thẻ tăng đủ số, khớp sao kê.
- "Số phải trả kỳ này" của thẻ = phần trả góp của kỳ đó (`GET /card-installments/due`) cộng phần client tự suy; lịch hiện các kỳ còn lại.
- Trả thẻ vẫn là chuyển khoản ví → thẻ, không phải chi tiêu mới. Phí chuyển đổi hoặc lãi là khoản chi riêng (danh mục phí), không cộng vào khoản mua hay vào kế hoạch.
- Trả trước hạn hoặc hủy: đóng lịch; khoản chi gốc không đổi.

## Mô hình

`CardInstallmentPlan` (migration `20261103200000_card_installments`, additive; deploy trước API): `transactionId` (unique, khoản chi gốc), `accountId` (ví thẻ), `totalMinor` (= |khoản chi|), `installmentMinor`, `installmentCount` (2–60), `firstDueOn`, `status` (`active` | `closed`), `closedAt`, `version`. Không có bảng kỳ: lịch suy ra từ các field trên.

## Lịch

Số nguyên (`bigint`). Mỗi kỳ trừ kỳ cuối trả `installmentMinor` (mặc định chia đều làm tròn lên); kỳ cuối nhận phần còn lại, phải dương và không lớn hơn một kỳ thường, nên tổng các kỳ luôn bằng giá mua. Kỳ theo tháng từ `firstDueOn`, giữ ngày trong tháng (31 → cuối tháng ngắn rồi quay lại 31). `firstDueOn` không trước ngày mua.

## API

Bearer session, `Cache-Control: no-store`, tiền là string integer.

| Endpoint | Việc |
|---|---|
| `POST /card-installments` | Tạo từ `transactionId`; 201, hoặc 200 khi replay cùng `clientId`. Khoản gốc phải là `expense` chưa xóa trên ví `credit` và chưa có kế hoạch (không thì 409); id lạ hoặc của người khác 400 |
| `POST /card-installments/preview` | Cùng input và kiểm tra như tạo (trừ `clientId`), không ghi; trả `installmentMinor`, `lastDueOn`, `periods` để app hiện lịch trước khi tạo bằng đúng số của server |
| `GET /card-installments` | Lọc `accountId`, `status`; mỗi dòng có `remainingCount`, `nextDueOn`, `nextAmountMinor`, và `purchaseOn` / `purchaseMerchant` / `purchaseNote` / `purchaseCategoryId` để app đặt tên kế hoạch |
| `GET /card-installments/{id}` | Kèm `periods` (`past` / `upcoming` / `closed`) |
| `GET /card-installments/due?from&to&accountId` | Tổng phần trả góp đến hạn trong khoảng, theo thẻ (chỉ kế hoạch `active`) |
| `POST /card-installments/{id}/close` | Đóng lịch, cần `version`; đóng lần hai → 409 |

`GET /transactions` và `GET /transactions/{id}` trả `installmentPlanId` trên khoản chi (kế hoạch còn chạy hoặc đã đóng, null nếu chưa có) để app biết khi nào hiện "Chuyển thành trả góp" (MOB-P3-009).

Xóa khoản chi gốc tự đóng kế hoạch đang chạy. Kế hoạch đã đóng vẫn giữ chỗ trên khoản chi đó (mỗi khoản chỉ một kế hoạch, tạo lại cần xóa dữ liệu). Có trong `GET /account/export` (`cardInstallmentPlans`) và xóa cùng tài khoản. Không log số tiền.

## Test

Unit: [card-installment.spec.ts](../../backend/api/src/modules/card-installments/domain/card-installment.spec.ts) (tổng các kỳ = giá mua, kỳ cuối nhận dư, cuối tháng, kỳ còn lại, tổng đến hạn). PostgreSQL: [card-installments.integration-spec.ts](../../backend/api/test/card-installments.integration-spec.ts) (báo cáo và số dư không đổi khi tạo, replay/xung đột, ví và loại không hợp lệ, `due`, đóng lịch rồi trả bằng transfer làm dư nợ giảm đúng, xóa khoản gốc).

**Tồn đọng:** chưa có nhắc đến hạn kỳ trả góp; chưa tạo lại kế hoạch sau khi đã đóng; khoản chi đã có hoàn tiền dùng số tiền gốc; chưa deploy staging.
