# Giao dịch định kỳ — BE-P2-E01 / MOB-P2-E01

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/recurring-transactions`. Module: [06-recurring](../product/modules/06-recurring.md).

## Mô hình

- `RecurringRule`: mẫu thu/chi/chuyển. Số tiền signed BigInt minor units. Chu kỳ `unit` (`day|week|month|year`) + `interval` 1–366 (preset = 1; custom = >1).
- `RecurringOccurrence`: một hàng mỗi `(ruleId, occurredOn)` — chống nhân đôi khi retry/worker/sync.
- `Transaction.recurringRuleId` nullable, `ON DELETE SET NULL` khi xóa rule.

## Lịch

- Ngày lịch theo `User.timezone` (`todayInTimeZone`).
- Tháng/năm giữ ngày mốc từ `startDate`, kẹp vào ngày cuối tháng (31/01 → 28/02 → 31/03).
- Tắt (`active=false`): không tạo, không đẩy `nextExecutionDate`. Bật lại chạy bù từ lần tới đang lưu.
- Mỗi lần `run`: tối đa 36 occurrence mỗi rule.

## Idempotency

- Tạo rule: `Idempotency-Key` = `clientId`, unique `(userId, clientId)`.
- Mỗi lần chạy: `clientId` leg = UUID ổn định từ SHA-256(`ruleId|YYYY-MM-DD|legIndex`). Create giao dịch đi cùng đường insert sổ cái; replay trả 200 / sync `replayed`.

## Worker

`RecurringWorker` mỗi 60 giây gọi `runDue(null)`. Không chạy khi `NODE_ENV=test`. Mobile gọi `POST .../run` lúc vào app và lúc resume (lỗi mạng im lặng). Rule không vào hàng đợi offline sync.
