# Gợi ý danh mục — BE-P5-E03 / MOB-P5-E03

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `POST /api/v1/category-suggestions/suggest`, `POST /api/v1/category-suggestions/feedback`, `GET /api/admin/category-suggestions/stats`. Màn: board R.1 (ghi chi), R.2–R.3 (nhập CSV, PR sau) — [pattern](../brand/patterns/R-suggestions-insights.md). Công tắc và danh sách đã nhớ: [auto-suggest.md](auto-suggest.md).

## Chức năng

Khi user gõ tên cửa hàng (hoặc ghi chú) lúc ghi chi/thu, app hỏi "Xếp vào Cà phê?". Bấm "Dùng" đổi danh mục; không bao giờ tự lưu giao dịch. Tính trên server của Freeva từ sổ của user, không gọi model, không gửi ra ngoài.

## Cách đoán (`domain/suggest.ts`, thuần)

Theo thứ tự, chỉ danh mục còn dùng (chưa lưu trữ) và đúng loại thu/chi:

1. **Đã nhớ**: `CategorySuggestionMapping` của cửa hàng (khóa `merchantKey`: trim, gộp khoảng trắng, chữ thường). `matchCount` = số lần trong lịch sử dùng danh mục đó.
2. **Lịch sử**: `categorySuggest.historySize` (mặc định 50) giao dịch gần nhất còn sống, cùng loại, có danh mục, cùng cửa hàng (không có cửa hàng thì cùng ghi chú). Danh mục nhiều nhất phải chiếm ≥ `categorySuggest.minConfidencePercent` (mặc định 60%) và không hòa. Lịch sử có mà không đủ chắc thì **không** gợi ý (không rơi xuống danh sách chung).
3. **Danh sách chung**: `categorySuggest.commonMerchants`, mỗi mục `"Tên: icon"`. Khớp nguyên từ, bỏ dấu, mục dài nhất thắng ("ShopeeFood" thắng "Shopee"). Icon trỏ tới danh mục của user có icon đó (ưu tiên danh mục mặc định, cấp cao nhất); không có thì icon gần nghĩa (`groceries` → `food`, `fuel` → `transport`…). Tra theo icon vì user đổi được tên danh mục.

Cửa hàng thắng ghi chú khi gửi cả hai. Kết quả: `{ category, source: remembered | history | common, matchCount, confidencePercent }` hoặc `null`.

Cờ `category_suggest` tắt hoặc user tắt Gợi ý tự động: `suggest` trả `{ suggestion: null }`, không đọc dữ liệu (`AutoSuggestPolicy`).

## Phản hồi và tỷ lệ

App gửi `POST /category-suggestions/feedback` sau khi lưu giao dịch mà đã thấy gợi ý: danh mục chọn trùng gợi ý = `accepted`, khác = `corrected` (không có nút "Không đúng"). Server:

- cộng vào `CategorySuggestionStat` (ngày UTC × `surface` entry/import × `source`), **không có cột user**;
- có `merchant` thì nhớ cửa hàng theo danh mục user chọn, kể cả khi sửa (chốt 2026-11-11: lần sau gợi ý đúng thứ user đã chọn).

Staff xem `GET /api/admin/category-suggestions/stats?from&to` (≤ 366 ngày): từng dòng, tổng và `acceptRatePercent`. Chưa có trang web admin.

## Cấu hình

| Khóa | Mặc định | Ghi chú |
|---|---|---|
| `categorySuggest.minConfidencePercent` | 60 | 50–100 |
| `categorySuggest.historySize` | 50 | 5–200 |
| `categorySuggest.commonMerchants` | ~50 cửa hàng VN | kiểu `pair_list` (mới): danh sách chuỗi `"Tên: icon"`, icon thuộc `CATEGORY_ICONS`, tên ≤ 60 ký tự, không trùng (bỏ dấu, hoa thường). Web admin nhập mỗi dòng một cặp |

## Riêng tư

Cửa hàng và ghi chú không log. Bảng đếm không có user id. Cửa hàng đã nhớ xuất/xóa như [auto-suggest.md](auto-suggest.md).

## App — ghi chi (MOB-P5-E03, board R.1)

Feature `lib/features/category_suggest/`. Màn ghi giao dịch **mới** (kể cả "chép thành mới"; không khi sửa) tạo `CategorySuggestViewModel`: đợi 400 ms sau phím cuối, cần ≥ 2 ký tự, dùng cửa hàng, không có thì ghi chú; chỉ câu trả lời mới nhất được cập nhật thẻ. Cờ `category_suggest` tắt hoặc loại Chuyển thì không gọi API. Thẻ dưới ô Cửa hàng: icon danh mục, "Xếp vào {danh mục}?", "Như N lần trước ở đây" (ẩn khi N = 0), nút "Dùng". Ẩn khi trùng danh mục đang chọn, danh mục không dùng được, xoá chữ, lỗi hay không có mạng (không toast). Lưu xong (kể cả lưu chờ đồng bộ) thì gửi phản hồi không chờ, lỗi bỏ qua, không vào hàng đồng bộ; không thấy gợi ý thì không gửi. Golden sáng/tối, đối chiếu board bằng `design_compare` nhóm `R`. Nền thẻ dùng `blue.50` theo pattern (board vẽ `#F7F9FE`, không phải token).
