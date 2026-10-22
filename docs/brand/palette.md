# Palette

Design system: [design-system.md](design-system.md) · tổng quan brand: [README.md](README.md).

Nguồn sự thật hex/token: [packages/design-tokens/tokens.json](../../packages/design-tokens/tokens.json).
Không hardcode hex trong UI. Kiểm tra tương phản: `node packages/design-tokens/scripts/check.mjs`.

## Brand (chốt theo board)

| Màu | Hex | Tỷ lệ diện tích | Dùng | Không dùng |
|---|---|---|---|---|
| Primary | `#5680E9` | 10–15% | Nút +, tab chọn, chuỗi dữ liệu 1, vòng focus | Chữ hoặc nền có chữ nhỏ (3.7:1) — dùng blue 600 |
| Accent | `#8860D0` | 3–5% | Logo, nhãn, chuỗi dữ liệu 2, chấm thông báo | Nền lớn |
| Secondary | `#5AB9EA` | 5–10% | Biểu đồ, thông tin, chuỗi dữ liệu 3 | Chữ body |
| Highlight | `#84CEEB` | có chọn lọc | Lớp màu mờ thẻ số dư, splash | **Chữ** |
| Muted | `#C1C8E4` | có chọn lọc | Nhóm "Khác" trong biểu đồ | **Chữ** |

Khoảng 75% diện tích là trung tính. Gradient/lớp màu mờ chỉ ở thẻ số dư và splash.

## Thang sắc độ

`primitive.color.{blue|cyan|violet}.{50…900}`, bậc 500 là màu gốc.

| Bậc | Blue | Cyan | Violet |
|---|---|---|---|
| 50 | `#EEF2FD` | `#EDF7FD` | `#F4F0FB` |
| 100 | `#DDE6FB` | `#D8EFFA` | `#E7DEF6` |
| 300 | `#99B2F2` | `#84CEEB` | `#B59BE2` |
| 500 | `#5680E9` | `#5AB9EA` | `#8860D0` |
| 600 | `#3F67D1` **nút, link** | `#3A9AD0` | `#7048B8` **chữ accent** |
| 700 | `#3352AA` nhấn | `#2A7FAE` **chữ** | `#5B3A96` |
| 800 | `#283F82` | `#1F6187` chữ info | `#452C72` |

Bậc 50 làm nền ô icon hai tông, bậc 600–700 làm nét/chữ trên nền đó.

## Trung tính (ink)

| Token semantic | Light | Dark |
|---|---|---|
| `bg.canvas` | `#FCFDFF` | `#12141F` |
| `bg.surface` | `#FFFFFF` | `#1B1F33` |
| `bg.subtle` | `#F4F6FB` | `#232842` |
| `bg.wash` (thẻ số dư) | `#ECEFFA` | `#232842` |
| `border.default` | `#E4E7F0` | `#2C3252` |
| `border.divider` | `#EEF0F5` | `#2C3252` |
| `text.primary` (ink) | `#22283A` | `#F4F6FB` |
| `text.secondary` | `#5C6378` | `#A9B0C7` |
| `text.onWash` | `#3D4460` | `#C9CEDD` |
| `text.link` | `#3F67D1` | `#99B2F2` |
| `action.primary` (nền nút) | `#3F67D1` | `#3F67D1` |
| `action.ink` (nav chọn, chip lọc, toast) | `#22283A` | `#F4F6FB` |

## Semantic tài chính

| Token | Light | Dark | Ghi chú |
|---|---|---|---|
| `money.income` | `#23795A` | `#7FD8B4` | Chữ số tiền thu, kèm dấu + |
| `money.expense` | `#22283A` | `#F4F6FB` | Khoản chi màu ink, kèm dấu − |
| `money.transfer` | `#5C6378` | `#A9B0C7` | Chuyển ví, không dấu |
| `status.success` / nền | `#23795A` / `#E9F5F0` | `#7FD8B4` / `#1D3A33` | |
| `status.danger` / nền | `#B83434` / `#FBECEC` | `#F29B9B` / `#3A2230` | Lỗi, vượt hạn mức, nút xoá |
| `status.warning` / nền | `#7A5A00` / `#FBF4E0` | `#E9C46A` / `#3A3222` | |
| `status.info` / nền | `#1F6187` / `#EDF7FD` | `#8DCFF0` / `#1E3346` | Đồng bộ, thông tin |

Màu gốc `#2F9E76`, `#D64545`, `#D4A017` chỉ dùng cho chấm, icon và thanh — không cho chữ
nhỏ. Không nhuộm primary thành đỏ/lục. Khoản chi **không** tô đỏ.

## Dữ liệu (biểu đồ)

Thứ tự cố định: `data.1` blue 500 → `data.2` violet 500 → `data.3` cyan 500 →
`data.4` muted `#C1C8E4` ("Khác"). Từ nhóm thứ 5 trở đi gộp vào "Khác". Kỳ không
được chọn trong biểu đồ cột dùng `data.muted` (blue 100).

## Legacy `color.*`

Nhánh `color.*` trong `tokens.json` giữ nguyên key vì là bảng màu danh mục của API
([ADR 012](../architecture/adr/012-design-tokens-v2.md)). Giá trị đã khớp v2: text
`#22283A`, canvas `#FCFDFF`, dark textMuted `#A9B0C7`.
