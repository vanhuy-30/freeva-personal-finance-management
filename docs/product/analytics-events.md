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

## Stub Flutter Phase 0

`MOB-P0-004` cung cấp `AnalyticsService` qua DI và implementation local ghi payload JSON ở mức debug. `AnalyticsEvent` chỉ có factory/constant cho catalog được duyệt; caller không thể truyền property tùy ý. Riêng `transaction_created` chỉ nhận `type` typed: `income`, `expense`, `transfer`.

Stub chưa gắn SDK/nhà cung cấp remote và không tự phát event từ splash/home placeholder. Feature Phase 1+ gọi `AnalyticsService` tại điểm nghiệp vụ thành công tương ứng; không dùng route/page placeholder để suy diễn funnel.
