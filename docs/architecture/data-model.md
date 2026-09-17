# Data model (Phase 0/1)

Logical + Prisma (ADR [007](adr/007-core-data-model.md)). Tiền / FX / TZ: ADR [006](adr/006-money-and-fx.md).

Module: [3 — ví](../product/modules/03-financial-accounts.md), [4 — GD](../product/modules/04-transactions.md), [5 — danh mục](../product/modules/05-categories.md), [20 — sync](../product/modules/20-sync.md).

## ER

```mermaid
erDiagram
  User ||--o{ FinancialAccount : owns
  User ||--o{ Category : owns
  User ||--o{ CategoryGroup : owns
  User ||--o{ Tag : owns
  User ||--o{ Transaction : books
  User ||--o{ FxQuote : quotes
  Currency ||--o{ User : default
  Currency ||--o{ FinancialAccount : denom
  Currency ||--o{ Transaction : denom
  Currency ||--o{ FxQuote : from
  Currency ||--o{ FxQuote : to
  CategoryGroup ||--o{ Category : groups
  Category ||--o{ Category : parent
  FinancialAccount ||--o{ Transaction : posts
  Category ||--o{ Transaction : classifies
  Transaction ||--o{ TransactionTag : tagged
  Tag ||--o{ TransactionTag : on
  FxQuote ||--o{ Transaction : rates
```

**AuditEvent** đã có Prisma (`BE-P0-004`, ADR [008](adr/008-audit-event-schema.md)); độc lập, không có FK tới actor/target. **Session** / **Device** hoãn tới Phase 1 auth.

## Quy tắc

- **Tiền:** integer minor units (`BigInt`). Không `float` / `double`. Signed: thu dương; chi âm; transfer nguồn âm, đích dương.
- **Số dư:** `initialBalanceMinor` ± giao dịch chưa xóa. Không cached balance.
- **Timezone:** `User.timezone` IANA, mặc định `Asia/Ho_Chi_Minh`. `occurredOn` = calendar date theo TZ user (`date`, không UTC wall-clock).
- **Kỳ tài chính:** `fiscalMonthStartDay` 1–28.
- **Transfer:** hai `Transaction` `type=transfer`, cùng `transferGroupId`; cân bằng ở use case Phase 1.
- **Credit:** chi tăng nợ (số dư derived âm hơn); thanh toán = transfer từ ví khác.
- **Soft-delete GD:** `deletedAt`. Ví/danh mục: `archivedAt`.
- **Idempotency / sync:** UUID `id`; unique `(userId, clientId)`; `version` monotonic.
- **Không double-count** với investment holdings (Phase 4).

## Field

Kiểu Prisma. Mọi bảng user-owned (trừ `User`, `Currency`, `SchemaMeta`, `TransactionTag`): `id` UUID, `userId`, `clientId`, `version`, `createdAt`/`updatedAt` timestamptz.

### Currency

| Cột | Kiểu | Ghi chú |
|---|---|---|
| code | String PK | ISO 4217 (`VND`, `USD`) |
| minorDigits | Int | VND = 0 |
| name | String | |

Catalog trống cho đến Phase 1 (không seed `BE-P0-001`).

### User

| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | UUID | |
| email | String unique | Không log đầy đủ |
| locale | String | mặc định `vi` |
| timezone | String | IANA; mặc định `Asia/Ho_Chi_Minh` |
| defaultCurrencyCode | FK Currency | |
| fiscalMonthStartDay | Int | 1–28 |
| version | Int | |
| createdAt / updatedAt | timestamptz | |

Không `passwordHash` — `BE-P1-001`.

### FinancialAccount

| Cột | Kiểu | Ghi chú |
|---|---|---|
| name | String | |
| type | enum | `cash` \| `bank` \| `ewallet` \| `credit` |
| currencyCode | FK Currency | |
| initialBalanceMinor | BigInt | |
| sortOrder | Int | |
| archivedAt | timestamptz? | |
| creditLimitMinor | BigInt? | chỉ credit |
| statementCloseDay | Int? | 1–28 |
| paymentDueDay | Int? | 1–28 |

Unique `(userId, clientId)`.

### CategoryGroup / Category

| Cột | Kiểu | Ghi chú |
|---|---|---|
| name | String | |
| isSystem | Boolean | bộ mặc định VN = `BE-P1-006` |
| archivedAt | timestamptz? | |
| groupId | FK? | Category → CategoryGroup |
| parentId | FK? | Category cây |
| colorToken | String? | tên token, không hex |
| iconToken | String? | |

Xóa danh mục: chuyển GD trước (Phase 1). Unique `(userId, clientId)`.

### Tag

`name` theo user. Unique `(userId, clientId)`. Gắn GD qua `TransactionTag` `(transactionId, tagId)`.

### Transaction

| Cột | Kiểu | Ghi chú |
|---|---|---|
| type | enum | `income` \| `expense` \| `transfer` |
| amountMinor | BigInt | signed |
| currencyCode | FK Currency | |
| occurredOn | date | theo TZ user |
| accountId | FK FinancialAccount | |
| categoryId | FK? | thường null với transfer |
| transferGroupId | UUID? | hai leg cùng giá trị |
| fxQuoteId | FK? | transfer khác currency |
| notes | String? | |
| deletedAt | timestamptz? | |

Index `(userId, occurredOn)`, `(transferGroupId)`. Unique `(userId, clientId)`.

### FxQuote

| Cột | Kiểu | Ghi chú |
|---|---|---|
| fromCode / toCode | FK Currency | |
| rate | Decimal | không phải tiền |
| quotedAt | timestamptz | |
| source | enum | `manual` \| `provider` |

Unique `(userId, clientId)`.

### SchemaMeta

Giữ từ scaffold: `version` schema ứng dụng / sync major. Health không phụ thuộc bảng này (`SELECT 1`).

### AuditEvent

Schema nội bộ, không thuộc nhóm bảng user-owned/sync ở trên. `WA-P0-002` có writer hẹp cho `staff.user_lookup`; các event khác chưa tích hợp.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | UUID PK | Prisma sinh mặc định |
| actorType | enum | `user`, `staff`, `system` |
| actorId | UUID? | Bắt buộc user/staff; null với system |
| action | varchar(100) | Mã ứng dụng, ví dụ `staff.user_lookup` |
| targetType | varchar(50) | Mã loại, ví dụ `user` |
| targetId | UUID? | Không FK |
| outcome | enum | `success`, `failure`, `denied`; không default |
| occurredAt / createdAt | timestamptz | Thời điểm xảy ra / lưu, mặc định `now()` |

SQL CHECK: actor hợp lệ; action/targetType khớp `^[a-z][a-z0-9._]*$`. Index `(actorType, actorId, occurredAt)`, `(targetType, targetId, occurredAt)`, `(occurredAt)`.

Không metadata hoặc dữ liệu tài chính/PII trực tiếp. UUID vẫn có thể liên kết người dùng. Xóa đối tượng không cascade audit; retention/xóa UUID và quyền audit chưa chốt. Bảng chưa được bảo vệ khỏi sửa/xóa; xem ADR 008.
