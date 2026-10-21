# ADR 012 — Design tokens v2: ba tầng, một nguồn

- **Status:** accepted
- **Date:** 2026-10-21
- **Task:** DS-P2-001

## Bối cảnh

`tokens.json` (DS-P0-001) chỉ có 5 màu brand, vài màu trung tính và semantic. Không có
thang sắc độ, typography, spacing, radius hay motion, nên widget tự đặt số. Màu
primary `#5680E9` không đạt AA khi làm chữ hoặc nền nút có chữ trắng (3.7:1).

Nhánh `color.*` còn được dùng làm bảng màu danh mục: backend sinh
`CATEGORY_COLORS` từ mọi lá của `tokens.color`, API trả về ở options và `colorToken`
đã lưu trong DB trỏ tới các key này.

## Quyết định

- `tokens.json` vẫn là nguồn duy nhất, thêm ba tầng: `primitive` → `semantic`
  (mỗi lá có `light`/`dark`) → `component`, cùng `typography`, `space`, `radius`,
  `size`, `layout`, `border`, `elevation`, `motion`. Tham chiếu dạng `{a.b.c}`.
- **Giữ nguyên key của nhánh `color.*`**; chỉ đổi giá trị cho khớp v2. Không thêm
  key mới vào nhánh này để bảng màu danh mục và API không đổi.
- `tokens.css` là file sinh ra bởi `scripts/build.mjs` (không còn sửa tay).
  `scripts/check.mjs` kiểm tra tham chiếu và tương phản AA ở cả hai mode.
- Script dùng Node thuần, không thêm Style Dictionary hay công cụ build mới.
- Flutter đọc token qua code sinh ra (DS-P2-002); cho tới lúc đó `AppColors` là bản
  chiếu tay và phải khớp giá trị `color.*`.

## Hệ quả

- Đổi token = sửa JSON + chạy build + check. Lệch giữa JSON và CSS bị `build --check` bắt.
- Muốn đổi tên hoặc bỏ key `color.*` phải có migration cho `colorToken` đã lưu.
- Bảng màu danh mục tương lai nên tách thành một nhánh riêng thay vì "mọi lá của `color`";
  ngoài phạm vi ADR này.
