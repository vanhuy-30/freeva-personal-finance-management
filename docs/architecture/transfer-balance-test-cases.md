# Transfer balance test cases

Spec bảng chuẩn cho `QA-P0-002`. Fixture máy đọc được là [`backend/api/test/fixtures/transfer-balance-cases.json`](../../backend/api/test/fixtures/transfer-balance-cases.json); Jest contract test kiểm tra fixture nhưng **chưa** triển khai ledger/use case `BE-P1-005`.

## Invariant được chốt

- Một transfer có đúng hai leg `type=transfer`, cùng `transferGroupId`.
- Leg nguồn âm, leg đích dương; tiền luôn là string integer minor units khi đi qua JSON.
- Cùng currency: `source.amountMinor + destination.amountMinor = 0`.
- Khác currency: cả hai leg tham chiếu cùng một `FxQuote` đã chốt; `fromCurrency`/`toCurrency` khớp hướng nguồn/đích.
- Fixture FX Phase 0 chỉ dùng phép đổi biểu diễn chính xác, không cần làm tròn:

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

## Ngoài phạm vi Phase 0

`BE-P1-005` phải chốt trước khi mở rộng fixture cho:

- rounding khi FX conversion không ra integer minor units;
- transfer amount bằng 0 và self-transfer cùng account;
- hai leg khác `occurredOn` hoặc trạng thái soft-delete không đồng nhất;
- transaction boundary, idempotency và hành vi khi chỉ ghi thành công một leg.

Khi implement `BE-P1-005`, dùng fixture này làm acceptance contract và thêm case mới thay vì sao chép bảng riêng.
