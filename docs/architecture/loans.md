# Vay và công nợ — BE-P3-E02 / MOB-P3-E02

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/loans`. Module: [10-loans](../product/modules/10-loans.md). Phần mobile (`MOB-P3-E02`) làm riêng. Cho mượn / đi mượn người quen không lãi là `BE-P3-007`.

## Mô hình

- `Loan`: loại (`card` | `personal` | `mortgage` | `other`), tên, tiền tệ, **gốc** (`principalMinor`), **dư nợ** (`outstandingMinor`, lưu cứng), lãi suất năm theo bps, số tiền mỗi kỳ (`installmentMinor`, tuỳ chọn), tần suất (`weekly` | `monthly` | `quarterly` | `yearly`), ngày bắt đầu / kết thúc / đến hạn tiếp theo, ví trả mặc định (tuỳ chọn), `archivedAt`, `version`.
- `LoanPayment`: một lần trả, tách `principalMinor` + `interestMinor`, `clientId` idempotent, trỏ hai chân expense (`principalTransactionClientId`, `interestTransactionClientId`).

## Tiền đi đâu

Không có việc nào tự chạy. Chỉ khi user gọi:

| Thao tác | Giao dịch | Audit |
|---|---|---|
| `POST /loans/{id}/payments` | expense phần gốc + expense phần lãi (mỗi phần > 0), cùng commit với dư nợ | không |
| `adjust` (sửa số đã có) | không | `loan.adjust` |
| tạo khoản vay | không | `loan.create` |

Mỗi expense cần danh mục (`principalCategoryId`, `interestCategoryId`) khi phần đó > 0. Chỉ phần gốc làm giảm dư nợ; trả quá dư nợ → `LOAN_OVERPAYMENT` (422). Retry cùng `clientId` trả kết quả cũ; khác nội dung → 409. Id chân giao dịch sinh cố định từ `clientId`. Sau khi trả, `nextDueDate` lùi một kỳ (cuối tháng thì cắt về ngày cuối); trả hết thì `null`.

**Tồn đọng:** báo cáo và ngân sách đếm mọi expense, nên phần gốc trả nợ hiện tính vào chi tiêu. Tách gốc khỏi báo cáo là việc sau.

## Công thức

Số nguyên (`bigint`), không `double`.

- `periodInterest = round_half_up(outstanding * rateBps / (10000 * kỳ_mỗi_năm))`. Ví dụ: 100.000.000, 12%/năm, theo tháng → 1.000.000.
- `annuityPayment`: số tiền kỳ cố định để hết nợ sau n kỳ, làm tròn lên (100tr, 12%, 12 tháng → 8.884.879).
- `schedule`: mỗi kỳ trả lãi trước, phần còn lại là gốc; kỳ cuối nhận phần dư làm tròn nên tổng gốc = dư nợ. `null` khi số kỳ không đủ trả lãi hoặc quá 600 kỳ.
- `splitPayment`: mặc định lãi của kỳ trước, phần còn lại là gốc.
- `status`: `paid_off` (dư nợ 0) · `overdue` (quá `nextDueDate`) · `active`.
- `percentBps = (principal - outstanding) * 10000 / principal`, làm tròn xuống.

## API

Bearer session, `Cache-Control: no-store`, tiền là string integer. `GET/POST /loans`, `GET/PATCH/DELETE /loans/{id}` (DELETE = lưu trữ, cần `version`), `GET /loans/summary` (gốc, đã trả, còn lại, lãi dự kiến theo tiền tệ), `GET /loans/{id}/schedule` (kèm giả định để user thấy và sửa input), `GET/POST /loans/{id}/payments`, `POST /loans/{id}/adjust`. Có trong `GET /account/export` (`loans`, `loanPayments`) và xoá theo user. Không log số tiền.
