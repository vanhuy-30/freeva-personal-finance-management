# Sync

## Nguyên tắc

- Mỗi bản ghi có `id` (UUID) do client hoặc server cấp; `clientId` idempotency bắt buộc khi tạo.
- `updatedAt` + `version` (monotonic) để conflict.
- MVP: last-write-wins theo field với queue; conflict giao dịch cùng id → server thắng + flag user review nếu amount khác.
- Schema version: client từ chối sync nếu major lệch; bắt migrate.
- Offline MVP: hàng đợi mutation, retry exponential, không CRDT.

## Chống trùng

Cùng user + amount + occurredOn + account + source hash trong cửa sổ N phút → gợi ý trùng, không im lặng drop.

Chi tiết implement: `BE-P0` / `MOB-P1` / `BE-P1`.
