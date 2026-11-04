# Vay và công nợ — BE-P3-E02 / MOB-P3-E02

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/loans`. Module: [10-loans](../product/modules/10-loans.md). Phần mobile: [mobile-debts-loans.md](mobile-debts-loans.md). Cho mượn / đi mượn người quen không lãi là `BE-P3-007`.

## Mô hình

- `Loan`: loại (`card` | `personal` | `mortgage` | `other`), tên, tiền tệ, **gốc** (`principalMinor`), **dư nợ** (`outstandingMinor`, lưu cứng), lãi suất năm theo bps, số tiền mỗi kỳ (`installmentMinor`, tuỳ chọn), tần suất (`weekly` | `monthly` | `quarterly` | `yearly`), ngày bắt đầu / kết thúc / đến hạn tiếp theo, ví trả mặc định (tuỳ chọn), `archivedAt`, `version`.
- `LoanPayment`: một lần trả, tách `principalMinor` + `interestMinor`, `clientId` idempotent, trỏ hai chân expense (`principalTransactionClientId`, `interestTransactionClientId`).

## Tiền đi đâu

Không có việc nào tự chạy. Chỉ khi user gọi:

| Thao tác | Giao dịch | Audit |
|---|---|---|
| `POST /loans/{id}/payments` | phần gốc: một giao dịch `debt` một chân (không danh mục); phần lãi: một expense (mỗi phần > 0), cùng commit với dư nợ | không |
| `adjust` (sửa số đã có) | không | `loan.adjust` |
| tạo khoản vay | không | `loan.create` |

Phần gốc là `debt` (như cho mượn / đi mượn, [personal-debts.md](personal-debts.md)): không vào thu/chi, ngân sách, tỷ lệ tiết kiệm, nhưng có trong số dư ví, lịch sử, export, sổ cái; `PATCH`/xoá qua `/transactions` bị chặn (400) để dư nợ không lệch. `principalCategoryId` không còn dùng (vẫn nhận cho app cũ). Phần lãi là chi phí: expense theo `interestCategoryId`, không gửi thì dùng danh mục chi "Lãi vay" đang hoạt động của user, chưa có thì tạo một lần làm danh mục hệ thống (`LOAN_INTEREST_CATEGORY`). Chỉ phần gốc làm giảm dư nợ; trả quá dư nợ → `LOAN_OVERPAYMENT` (422). Retry cùng `clientId` trả kết quả cũ; khác nội dung → 409. Id chân giao dịch sinh cố định từ `clientId`. Sau khi trả, `nextDueDate` lùi một kỳ (cuối tháng thì cắt về ngày cuối); trả hết thì `null`.

Migration `20261104100000_loan_principal_debt` (chỉ đổi dữ liệu) chuyển các chân gốc đã ghi là expense trước đó sang `debt`, bỏ danh mục, tăng `version` để thiết bị tải lại; bỏ qua dòng đã có hoàn tiền hoặc kế hoạch trả góp thẻ.

## Công thức

Số nguyên (`bigint`), không `double`.

- `periodInterest = round_half_up(outstanding * rateBps / (10000 * kỳ_mỗi_năm))`. Ví dụ: 100.000.000, 12%/năm, theo tháng → 1.000.000.
- `annuityPayment`: số tiền kỳ cố định để hết nợ sau n kỳ, làm tròn lên (100tr, 12%, 12 tháng → 8.884.879).
- `schedule`: mỗi kỳ trả lãi trước, phần còn lại là gốc; kỳ cuối nhận phần dư làm tròn nên tổng gốc = dư nợ. `null` khi số kỳ không đủ trả lãi hoặc quá 600 kỳ.
- `splitPayment`: mặc định lãi của kỳ trước, phần còn lại là gốc.
- `status`: `paid_off` (dư nợ 0) · `overdue` (quá `nextDueDate`) · `active`.
- `percentBps = (principal - outstanding) * 10000 / principal`, làm tròn xuống.
- Ngày từng kỳ (`schedule.items[].dueDate`): kỳ 1 = `nextDueDate`, mỗi kỳ sau lùi một kỳ bằng cùng hàm với lúc trả (`addPeriod`, cắt cuối tháng); không có `nextDueDate` thì `null`.
- `summary.items[].dueThisMonthMinor`: tổng số tiền các kỳ có `dueDate` trong tháng hiện tại theo múi giờ hồ sơ; kỳ quá hạn của tháng trước không tính. Khoản vay không có số trả mỗi kỳ không có lịch nên không góp vào.

## API

Bearer session, `Cache-Control: no-store`, tiền là string integer. `GET/POST /loans`, `GET/PATCH/DELETE /loans/{id}` (DELETE = lưu trữ, cần `version`), `GET /loans/summary` (gốc, đã trả, còn lại, lãi dự kiến theo tiền tệ), `GET /loans/{id}/schedule` (kèm giả định để user thấy và sửa input), `GET/POST /loans/{id}/payments`, `POST /loans/{id}/adjust`. Có trong `GET /account/export` (`loans`, `loanPayments`) và xoá theo user. Không log số tiền.
