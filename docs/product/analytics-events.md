# Analytics events (stub)

Catalog sẽ mở rộng khi có SDK. Không gửi PII (email, số dư, số TK) trong property.

## Funnel cốt lõi

| Event | Khi nào |
|---|---|
| `onboarding_started` | Mở bước đầu |
| `onboarding_completed` | Xong onboarding |
| `auth_signed_up` | Đăng ký thành công |
| `auth_signed_in` | Đăng nhập |
| `wallet_created` | Tạo ví đầu / tiếp |
| `transaction_created` | Ghi GD (type: income/expense/transfer) |
| `report_viewed` | Mở báo cáo đầu / lần sau |

## Chất lượng / trust

`transaction_edited`, `transaction_deleted`, `sync_failed`, `export_requested`, `account_deletion_requested`.

## Feature flag / consent

`notifications_opt_in`, `ai_opt_in` (Phase 5+), `bank_connect_started` (Phase 6).

Đặt tên snake_case, version trong payload `schema_version: 1`.
