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

## Kiểu giá trị

| Kiểu | Quy tắc |
|---|---|
| `integer` | số nguyên trong `min`–`max` |
| `integer_list` | số nguyên trong `min`–`max`, không trùng, tăng dần, số phần tử `minItems`–`maxItems` |
| `money_minor_list` | chuỗi minor units dương (như API tiền), tăng dần, có `currencyCode` |
| `enum` / `enum_list` | thuộc `values`; danh sách không trùng, giữ thứ tự staff đặt |
| `time` | `HH:mm` |

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
| `CONFIG_KEY_UNKNOWN` | 404 |
| `CONFIG_CONFLICT` | 409 |
| `FEATURE_DISABLED` | 403 |
| `APP_CONFIG_UNAVAILABLE` | 503 |

Staff auth giữ như `WA-P0-002` (`STAFF_AUTH_*`); auth single-staff vẫn phải thay trước production. Mọi response `Cache-Control: no-store`; API không cache, mỗi request đọc hai bảng nhỏ.

## Dữ liệu

Migration `20261111120000_app_config` additive: `FeatureFlag`, `AppConfigValue`, `AppConfigChange`, `AppConfigMeta` (seed id 1). Không có dòng nào thì hành vi không đổi.

## Code

`backend/api/src/modules/app-config/`: `domain/app-config.ts` (kiểm tra giá trị, tính cờ, thuần), `domain/app-config-registry.ts`, `domain/app-config.repository.ts`, `infrastructure/prisma-app-config.repository.ts`, service, hai controller, `feature.guard.ts`. Test: `app-config.spec.ts`, `test/app-config.integration-spec.ts`.
