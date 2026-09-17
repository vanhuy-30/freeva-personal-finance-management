# ADR 007 — Core financial data model

- **Status:** accepted
- **Date:** 2026-08-31
- **Deciders:** engineering
- **Task:** `BE-P0-001`

## Context

Phase 0 cần chốt schema lõi (user, ví, giao dịch, danh mục, tiền tệ, FX) trước CRUD Phase 1. ADR [006](006-money-and-fx.md) đã chốt biểu diễn tiền và TZ; ADR này chốt cấu trúc bảng PostgreSQL / Prisma.

## Decision

### Định danh và sync

- `id` UUID (`@db.Uuid`), client hoặc server cấp.
- `clientId` UUID unique theo `(userId, clientId)` trên bản ghi user-owned cần idempotency (ví, giao dịch, nhóm/danh mục, nhãn, FxQuote).
- `version` Int monotonic (bắt đầu 1) cho conflict/sync (module 20).
- `createdAt` / `updatedAt` = `timestamptz`.

### Tiền

- Mọi số tiền: Prisma `BigInt` minor units. Cấm `Float` / `Double` / `Decimal` cho tiền.
- Cột `currencyCode` ISO 4217, FK tới `Currency.code`.
- **Signed minor units:** thu dương; chi âm; transfer leg nguồn âm, leg đích dương.
- JSON API (Phase 1) vẫn string integer theo ADR 006.
- Số dư ví **derived**: `initialBalanceMinor` + tổng `amountMinor` giao dịch chưa `deletedAt`. Không cột cached balance.

### Tỷ giá

- `FxQuote.rate` = `Decimal` (tỷ giá, không phải tiền) + `quotedAt` + `source` (`manual` | `provider`).
- MVP: nhập tay. Không auto-FX.

### Timezone và ngày tài chính

- `User.timezone` IANA, mặc định `Asia/Ho_Chi_Minh`.
- `Transaction.occurredOn` = date-only (`@db.Date`): calendar date theo TZ user, không wall-clock UTC.
- `User.fiscalMonthStartDay` = 1–28 (kỳ báo cáo).

### Transfer

- Hai hàng `Transaction` `type=transfer`, cùng `transferGroupId`.
- Cùng currency: `amountMinor` nguồn + đích = 0.
- Khác currency: mỗi leg gắn `fxQuoteId` đã chốt.
- Cân bằng enforce ở use case Phase 1 (`BE-P1-005`); schema chỉ đủ cấu trúc (index `transferGroupId`).

### Credit

- `FinancialAccount.type = credit`. Chi (âm) làm số dư derived càng âm (nợ tăng). Thanh toán = transfer từ ví khác.
- Optional: `creditLimitMinor`, `statementCloseDay`, `paymentDueDay`.

### Xóa / lưu trữ

- Giao dịch: soft-delete `deletedAt` (khôi phục cửa sổ ngắn — Phase 1).
- Ví / danh mục / nhóm: `archivedAt`. Không hard-delete khi còn GD.

### User

- Identity + hồ sơ: `email` unique, `locale`, `timezone`, `defaultCurrencyCode`, `fiscalMonthStartDay`.
- Không `passwordHash` / session — `BE-P1-001` / `BE-P1-002`.

### Hoãn Prisma (nêu trên ER logical)

- `AuditEvent` — hoãn tại thời điểm ADR 007; đã bổ sung bởi `BE-P0-004`, xem [ADR 008](008-audit-event-schema.md).
- `Session` / `Device` — Phase 1 auth.

### Catalog

- `Currency` là bảng catalog (`code`, `minorDigits`, `name`). VND: `minorDigits = 0`. Không seed trong task này; Phase 1 insert khi tạo user/ví.

## Consequences

- Prisma schema khớp [data-model.md](../data-model.md). CRUD/OpenAPI là Phase 1.
- Báo cáo so sánh số nguyên; helper [`backend/api/src/core/money`](../../../backend/api/src/core/money/money.ts).
- Investment holdings (Phase 4) không double-count với ví tiền.
