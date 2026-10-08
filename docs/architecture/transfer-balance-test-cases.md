# Transfer balance test cases

Spec bảng chuẩn cho `QA-P0-002`. Fixture máy đọc được là [`backend/api/test/fixtures/transfer-balance-cases.json`](../../backend/api/test/fixtures/transfer-balance-cases.json); Jest contract test chạy evaluator domain production của `BE-P1-005`. HTTP/PostgreSQL regression kiểm tra mutation nguyên tử, rollback và concurrency.

## Invariant được chốt

- Một transfer có đúng hai leg `type=transfer`, cùng `transferGroupId`.
- Leg nguồn âm, leg đích dương; tiền luôn là string integer minor units khi đi qua JSON.
- Cùng currency: `source.amountMinor + destination.amountMinor = 0`.
- Khác currency: cả hai leg tham chiếu cùng một `FxQuote` đã chốt; `fromCurrency`/`toCurrency` khớp hướng nguồn/đích.
- FX chỉ chấp nhận phép đổi exact (gồm rate thập phân), từ chối kết quả cần làm tròn:

```text
destinationMinor = abs(sourceMinor) × rate × 10^destinationMinorDigits
                   / 10^sourceMinorDigits
```

Contract test không dùng `number`, `float` hoặc `double` để tính tiền.

## Bảng ca kiểm thử

| ID | Kỳ vọng | Trường hợp | Reason code |
|---|---|---|---|
| `TR-SAME-001` | Accept | VND `-150000` / `+150000`, cùng group | `BALANCED_SAME_CURRENCY` |
| `TR-SAME-002` | Reject | VND `-150000` / `+140000` | `UNBALANCED_SAME_CURRENCY` |
| `TR-SAME-003` | Reject | Tổng bằng 0 nhưng dấu nguồn/đích bị đảo | `INVALID_SIGN_DIRECTION` |
| `TR-STRUCT-001` | Reject | Chỉ có source leg | `REQUIRES_EXACTLY_TWO_LEGS` |
| `TR-STRUCT-002` | Reject | Ba leg dù tổng bằng 0 | `REQUIRES_EXACTLY_TWO_LEGS` |
| `TR-STRUCT-003` | Reject | Hai leg khác `transferGroupId` | `GROUP_MISMATCH` |
| `TR-STRUCT-004` | Reject | Một leg không có `type=transfer` | `NON_TRANSFER_LEG` |
| `TR-FX-001` | Accept | USD 10.00 → VND 250000, rate 25000 | `BALANCED_EXACT_FX` |
| `TR-FX-002` | Reject | Một FX leg thiếu quote | `FX_QUOTE_REQUIRED_ON_BOTH_LEGS` |
| `TR-FX-003` | Reject | Quote USD/EUR dùng cho transfer USD/VND | `FX_QUOTE_CURRENCY_MISMATCH` |
| `TR-FX-004` | Reject | Amount đích không khớp phép đổi exact | `FX_AMOUNT_MISMATCH` |

## Bổ sung BE-P1-005

| ID | Kỳ vọng | Trường hợp | Reason code |
|---|---|---|---|
| `TR-SAME-004` | Reject | Zero transfer | `INVALID_SIGN_DIRECTION` |
| `TR-STRUCT-005` | Reject | Cùng ví | `SELF_TRANSFER` |
| `TR-STRUCT-006` | Reject | Khác ngày | `DATE_MISMATCH` |
| `TR-STRUCT-007` | Reject | Chỉ xóa một leg | `DELETE_STATE_MISMATCH` |
| `TR-FX-005` | Accept | Rate thập phân, kết quả nguyên | `BALANCED_EXACT_FX` |
| `TR-FX-006` | Reject | Kết quả có phần lẻ minor units | `FX_AMOUNT_MISMATCH` |

API nhận cùng ngày/trạng thái cho cả cặp, server cấp group/quote; không cho client viết từng leg transfer độc lập. Self-transfer và zero bị từ chối. FX không làm tròn ngầm. Cả hai leg, quote và tag links cùng transaction; lỗi leg thứ hai rollback leg thứ nhất. ClientId replay và optimistic version được kiểm tra theo toàn bộ cặp. Chi tiết: [transactions.md](transactions.md).
