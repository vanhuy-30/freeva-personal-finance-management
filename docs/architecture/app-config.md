# Cờ và cấu hình phía server — BE-P5-E08

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `GET /api/v1/app-config`, `GET /api/admin/app-config`, `PUT /api/admin/app-config/flags/{key}`, `PUT /api/admin/app-config/values/{key}`, `DELETE /api/admin/app-config/values/{key}`. Màn web admin: `WA-P5-001`, trang `/config` (`apps/web-admin/src/app/config/`). App đọc: `MOB-P5-E08` ([mobile-app-config.md](mobile-app-config.md)).

## Chức năng

Server giữ cờ bật/tắt tính năng và các số cấu hình sản phẩm (ngưỡng, giới hạn, danh sách lựa chọn) để app không hardcode (quyết định 2026-11-11, DECISIONS-OPEN #13). Staff sửa trên web admin; app nhận giá trị mới ở lần tải cấu hình kế tiếp, không cần phát hành bản mới.

## Định nghĩa trong code, giá trị trong DB

`modules/app-config/domain/app-config-registry.ts` khai báo mọi cờ và khóa: kiểu, mặc định, giới hạn, mô tả. DB chỉ lưu phần staff đã sửa:

- Không có dòng `FeatureFlag` thì cờ tắt. Không có dòng `AppConfigValue` thì dùng mặc định trong code.
- Mặc định bằng giá trị app và API đang dùng (danh sách rà soát ở `BE-P5-001`). Khóa nào backend đã có hằng số thì registry import chính hằng số đó.
- Khóa là giới hạn kỹ thuật (số dòng nhập/xuất CSV, độ dài cột) chỉ hạ được: `max` bằng giá trị hiện tại.
- Giá trị đã lưu mà không còn hợp định nghĩa (định nghĩa siết lại sau) thì trả mặc định; admin thấy `isDefault: true`.
- Thêm khóa: khai báo trong registry, rồi cho app và API đọc nó trong cùng task.

Mỗi môi trường (local, staging, production) có DB riêng nên tự quản cờ của mình; không có cột môi trường.

## Server dùng giá trị đã sửa (BE-P5-001)

`AppConfigReader` (module `AppConfigCoreModule`, không phụ thuộc `AuthModule` nên module nào cũng import được) trả giá trị có kiểu của một khóa; cache trong process 30 giây, staff lưu thì xóa cache của process đó (instance khác cập nhật trong ≤ 30 giây). Decorator DTO giữ làm trần cứng, service kiểm tra thêm giá trị đã sửa:

| Khóa | Nơi dùng |
|---|---|
| `budget.defaultAlertThresholds`, `budget.maxAlertThresholds` | `BudgetService` (`normalizeAlertThresholds`) |
| `forecast.defaultMonths` | `ForecastService` |
| `recurring.defaultRemindBefore` | `RecurringService` |
| `creditCard.highUsagePercent`, `creditCard.criticalUsagePercent` | `NotificationService` (cảnh báo dùng thẻ) |
| `notification.dailyLogDefaultTime`, `quietStartDefault`, `quietEndDefault` | `PrismaNotificationRepository` (user chưa lưu cài đặt) |
| `import.maxRows` | `TransactionImportService` (`parseRows`, 413 `FILE_TOO_LARGE`) |
| `export.csvMaxRows` | `TransactionService.exportCsv` |
| `transaction.maxTags` | `TransactionService` tạo/sửa (cả `/sync`) |
| `profile.displayNameMaxLength`, `onboarding.maxGoals` | `ProfileService` |
| `password.minLength` | `AuthService` đăng ký, đặt lại, đổi mật khẩu (đăng nhập giữ mức DTO để mật khẩu cũ vẫn vào được) |

Mốc ngân sách: server báo ở **mọi mốc user đã chọn** (bỏ sàn 80% cũ, chốt 2026-11-11).

**Khóa chỉ đọc (`editable: false`, nhóm `limit.*`):** giới hạn kỹ thuật API áp dụng nguyên (độ dài tên, ghi chú, mật khẩu, email; ngày đầu kỳ 28; mốc 100; dự báo 12; trả góp 2–60; nhắc trước 30; lặp 366; lãi suất; khoảng báo cáo 3660 ngày; 1 000 000 ký tự CSV). `/app-config` trả để app báo trước cho user; staff chỉ xem, sửa trả `400 CONFIG_KEY_READONLY`. Test `registry-limits.spec.ts` so từng khóa với decorator DTO để hai bên không lệch.

**Kiểm tra chéo khi lưu** (`crossCheckConfig`): số mốc mặc định ≤ số mốc tối đa; `forecast.defaultMonths` ∈ `monthOptions`; `installment.defaultTerm` ∈ `termOptions`; `recurring.defaultRemindBefore` ∈ `remindBeforeOptions`; mức dùng thẻ cao < nguy hiểm; `password.veryStrongLength` ≥ `password.minLength`. Sai → `400 CONFIG_VALUE_INVALID` kèm lý do.

**Không cần đăng nhập:** `GET /api/v1/app-config/public` trả `{ version, config }` (không cờ, không dữ liệu user) từ cache của reader, để màn trước khi đăng nhập (quy tắc mật khẩu…) cũng đọc số từ server (chốt 2026-11-11).

**Tiền tệ:** `Currency.symbol` (VND `₫`), `GET /profile/options` trả `{ code, minorDigits, symbol, isDefault }`; `isDefault` là tiền tệ tài khoản mới (`NEW_USER_CURRENCY_CODE`, dùng chung cho đăng ký email và OAuth).

## Kiểu giá trị

| Kiểu | Quy tắc |
|---|---|
| `integer` | số nguyên trong `min`–`max` |
| `integer_list` | số nguyên trong `min`–`max`, không trùng, tăng dần, số phần tử `minItems`–`maxItems` |
| `money_minor_list` | chuỗi minor units dương (như API tiền), tăng dần, có `currencyCode` |
| `enum` / `enum_list` | thuộc `values`; danh sách không trùng, giữ thứ tự staff đặt |
| `time` | `HH:mm` |
| `pair_list` | danh sách chuỗi `"Tên: giá trị"`, giá trị sau dấu `:` cuối thuộc `values`, tên ≤ `maxTextLength`, không trùng (bỏ dấu, hoa thường); web admin nhập mỗi dòng một cặp (`BE-P5-E03`) |

## Cờ

`enabled` là công tắc tổng; `userIds` (tối đa 500 UUID) luôn bật khi cờ bật; còn lại theo `percentage`: `sha256(key + ':' + userId)` lấy 4 byte đầu `% 100 < percentage`. Một user luôn rơi vào cùng nhóm của một cờ, và mỗi cờ chia nhóm khác nhau.

Cờ hiện có, mặc định tắt: `category_suggest`, `insights`, `forecast`, `google_sign_in`, `apple_sign_in`, `profile_edit`.

Chặn API: `@UseGuards(AuthGuard, FeatureGuard)` + `@RequireFeature('insights')` trả `403 FEATURE_DISABLED`. Guard ném `HttpException` có error envelope nên filter của module sở hữu route trả nguyên.

## Version và ghi đè

- `AppConfigMeta.version` (một dòng) tăng mỗi lần sửa; `GET /app-config` trả nó để app biết khi nào thay bản đã lưu.
- Mỗi cờ/khóa có `version` riêng (0 khi chưa lưu). Staff gửi version đã thấy; lệch thì `409 CONFIG_CONFLICT`, không ghi gì.

## Ghi và audit

Mỗi lần sửa là một `prisma.$transaction`: kiểm tra version → ghi giá trị → ghi `AppConfigChange` (`kind`, `key`, `before`, `after`, `actorId`) → ghi `AuditEvent` `staff.app_config_update` (`targetType: app_config`) → tăng version toàn cục. Lỗi bất kỳ thì không gì được lưu (fail closed). `AuditEvent` không có cột payload nên trước/sau nằm ở `AppConfigChange`. Không có dữ liệu tài chính.

Xóa tài khoản gỡ UUID của user khỏi `FeatureFlag.userIds` trong cùng transaction xóa và tăng version cờ đó, để admin đang mở bản cũ không ghi lại UUID.

## Lỗi

| Mã | HTTP |
|---|---|
| `CONFIG_VALUE_INVALID` (`details[0].reason`) | 400 |
| `CONFIG_KEY_READONLY` | 400 |
| `CONFIG_KEY_UNKNOWN` | 404 |
| `CONFIG_CONFLICT` | 409 |
| `FEATURE_DISABLED` | 403 |
| `APP_CONFIG_UNAVAILABLE` | 503 |

Staff auth giữ như `WA-P0-002` (`STAFF_AUTH_*`); auth single-staff vẫn phải thay trước production. Mọi response `Cache-Control: no-store`; API không cache, mỗi request đọc hai bảng nhỏ.

## Dữ liệu

Migration `20261111150000_config_enforce` (BE-P5-001): `Currency.symbol`, default `dailyLogTime` = `21:00` (dòng cũ giữ giờ đã lưu). Migration `20261111120000_app_config` additive: `FeatureFlag`, `AppConfigValue`, `AppConfigChange`, `AppConfigMeta` (seed id 1). Không có dòng nào thì hành vi không đổi.

## Code

`backend/api/src/modules/app-config/`: `domain/app-config.ts` (kiểm tra giá trị, tính cờ, thuần), `domain/app-config-registry.ts`, `domain/app-config.repository.ts`, `infrastructure/prisma-app-config.repository.ts`, service, hai controller, `feature.guard.ts`. Test: `app-config.spec.ts`, `test/app-config.integration-spec.ts`.
