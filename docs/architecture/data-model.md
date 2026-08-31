# Data model (Phase 0/1)

Logical model — Prisma đầy đủ khi `BE-P0-001`. Scaffold hiện chỉ có bảng `_meta` / health.

## Thực thể cốt lõi

- **User** — identity, locale, defaultCurrency, timezone, fiscalMonthStartDay, consent.
- **FinancialAccount** — type (cash|bank|ewallet|credit), currency, initialBalanceMinor, archivedAt.
- **Category** / **CategoryGroup** — system vs user, parent, archived.
- **Tag**
- **Transaction** — type income|expense|transfer, amountMinor, currency, occurredOn, accountId, transferPairId, categoryId, notes, deletedAt, clientId (idempotency).
- **FxQuote** — from, to, rate, quotedAt, source (manual|provider).
- **Device / Session**
- **AuditEvent** — actor, action, resource, at (không chứa số dư).
- **SchemaVersion** — cho sync/migration.

## Quy tắc

- Soft-delete giao dịch: `deletedAt`; khôi phục trong cửa sổ ngắn.
- Credit card: debt tăng khi chi; thanh toán là transfer từ ví khác.
- Không double-count với investment holdings (Phase 4).
