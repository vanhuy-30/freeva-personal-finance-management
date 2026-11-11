# Gợi ý tự động — tắt và xoá dữ liệu đã học — PRD-P5-E01

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `PUT /api/v1/profile/auto-suggest`, `GET` / `DELETE /api/v1/category-suggestions/mappings`, `DELETE /api/v1/category-suggestions/mappings/{id}`. Màn app: `MOB-P5-002`, board U.1, U.2 ([pattern](../brand/patterns/R-suggestions-insights.md)).

## Chức năng

Người dùng tắt cả ba loại gợi ý của Phase 5 bằng một công tắc: gợi ý danh mục (`BE-P5-E03`), điều đáng chú ý (`BE-P5-E04`), dự báo chi và ngày dự kiến đạt mục tiêu (`BE-P5-E06`). Mọi gợi ý tính trên server của Freeva từ sổ của chính user, không gửi ra ngoài. Đồng ý dùng AI bên ngoài là việc của `PRD-P8-E02`.

## Công tắc

`User.autoSuggestEnabled`, mặc định `true` (user cũ cũng bật). `GET /profile` trả trường này (chỉ đọc trên `PUT /profile`); `PUT /profile/auto-suggest` `{ "enabled": false }` lưu ngay, không kiểm version.

`AutoSuggestPolicy.allows(feature, userId)` (module `category-suggestions`, export cho module khác) là câu trả lời duy nhất cho "user này có được gợi ý không": cờ server của tính năng (`category_suggest`, `insights` hoặc `forecast`) bật cho user **và** công tắc của user bật. `E03`, `E04`, `E06` gọi nó trước khi tính; `false` thì trả kết quả rỗng (không lỗi), để app chỉ cần ẩn khối. Cờ tắt thì không đọc DB user.

## Dữ liệu đã học

Bảng `CategorySuggestionMapping`: một dòng mỗi cửa hàng của user (`@@unique(userId, merchantKey)`), trỏ tới danh mục user đã chọn. `merchantKey` = trim, gộp khoảng trắng, chữ thường (`merchantKey()` trong domain). `merchant` giữ cách viết gần nhất để hiển thị. `E03` ghi bảng này khi user chấp nhận hoặc sửa gợi ý; task này chỉ tạo bảng và API xem/xoá.

- `GET /category-suggestions/mappings` trả `{ items, total }`, mới nhất trước, mỗi dòng kèm tên, icon, màu của danh mục.
- `DELETE /category-suggestions/mappings/{id}` quên một cửa hàng (`404 MAPPING_NOT_FOUND` nếu không phải của user); `DELETE /category-suggestions/mappings` xoá hết. Giao dịch không đổi.
- Không chặn bằng cờ: user luôn xem và xoá được dữ liệu đã học, kể cả khi cờ hoặc công tắc đã tắt.
- Tắt công tắc không xoá dòng nào; chỉ "Xoá dữ liệu đã học" mới xoá.

Insight **không lưu** trên server (chốt 2026-11-11): tính mỗi lần xem, nên "dữ liệu đã học" chỉ là danh sách cửa hàng.

## Xuất và xoá tài khoản

Xuất JSON có `profile.autoSuggestEnabled` và `categorySuggestionMappings` (`id`, `merchant`, `categoryId`, mốc thời gian). Xoá tài khoản xoá bảng này trước danh mục; khoá ngoại tới `User` và `Category` đều `ON DELETE CASCADE`.

## Riêng tư

Tên cửa hàng là dữ liệu tài chính: không log, filter của module trả `503 SUGGESTIONS_UNAVAILABLE` không kèm thông điệp DB.

## App (MOB-P5-002)

Feature `lib/features/auto_suggest/`. Dòng "Gợi ý tự động" (icon lấp lánh, Bật/Tắt) ở Cá nhân → Ứng dụng sau Thông báo, chỉ hiện khi ít nhất một cờ `category_suggest`, `insights`, `forecast` bật. Màn `/me/auto-suggest` (U.1): công tắc lưu ngay (đổi trên màn trước, lỗi thì trả lại + toast), danh sách 4 dòng đầu và "Xem cả N", × quên từng cửa hàng, "Xoá dữ liệu đã học" mở hộp xác nhận chung (U.2). Không có cửa hàng nào (hoặc tải lỗi) thì ẩn nhóm và nút xoá. Quên một dòng mà API báo lỗi thì tải lại danh sách: dòng đã mất coi như đã quên. `Profile.autoSuggestEnabled` mặc định `true` khi server không trả, không gửi lên `PUT /profile`. Golden U.1 sáng/tối/trống và U.2, đối chiếu board bằng `design_compare` nhóm `U`.
