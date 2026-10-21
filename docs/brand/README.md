# Brand / UI design system

Board brand gốc (logo, 5 màu): [ui-design-system.png](ui-design-system.png).

![Freeva UI design system](ui-design-system.png)

| Tài liệu | Nội dung |
|---|---|
| [design-system.md](design-system.md) | **Design system v2** (DS-P2-001): nguyên tắc, foundations, token, components, trạng thái, patterns, guidelines. UI mới bám theo tài liệu này. |
| [design-progress.md](design-progress.md) | **Tiến độ thiết kế từng nhóm màn và cách làm tiếp** — đọc trước khi thiết kế tiếp |
| [patterns/](patterns/) | Thiết kế đã chốt theo nhóm màn (A: onboarding + tài khoản · B: tổng quan · C: giao dịch) |
| [canvas/](canvas/) | Bản sao nguồn canvas (`.dc.html`) |
| [palette.md](palette.md) | Bảng màu, thang sắc độ, token semantic light/dark |
| [`packages/design-tokens`](../../packages/design-tokens/) | Nguồn hex và mọi token; `tokens.css` sinh từ `tokens.json` |
| [references/](references/) | Ảnh tham chiếu phong cách dùng khi dựng v2 |
| [Canvas thiết kế](https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T) | Board trực quan (riêng tư, cần được chia sẻ) |

Không copy UI Facebook/Timelikes. UI sản phẩm chỉ dùng token brand/semantic — không hardcode hex trong widget/component.

## Tên và thông điệp

| Vai trò | Nội dung |
|---|---|
| Wordmark | **FREEVA** (all-caps, sans-serif hình học; chữ **A** có tam giác accent thay thanh ngang) |
| Tagline chính | YOUR MONEY. A BRIGHTER TOMORROW. |
| Tagline phụ | PLAN · BUILD · GROW · BE FREE |

## Logo

Ba biến thể trên board — dùng đúng file PNG dưới đây; giữ tỷ lệ, khoảng trống và màu; không tự vẽ lại bằng icon generic. Chưa có SVG vector trong repo.

| Biến thể | File | Caption trên board |
|---|---|---|
| **Brand symbol** | [freeva-brand-symbol.png](freeva-brand-symbol.png) — F stylized, ba nét cong (xanh → cyan → tím), nền đen | FREEDOM IN MOTION |
| **Horizontal lockup** | [freeva-logo-lockup.png](freeva-logo-lockup.png) — symbol + wordmark FREEVA (chữ A có tam giác accent) | A BRIGHTER FINANCIAL YOU |
| **App icon** | [freeva-app-icon.png](freeva-app-icon.png) — symbol trắng/glass trên gradient xanh → tím | READY FOR WHAT'S NEXT |

### Brand symbol

![Freeva brand symbol](freeva-brand-symbol.png)

### Horizontal lockup

![Freeva logo lockup](freeva-logo-lockup.png)

### App icon

![Freeva app icon](freeva-app-icon.png)

## Palette (tóm tắt board)

Năm màu brand trên board (chi tiết dùng/cấm: [palette.md](palette.md)):

| Hex | Token | Tỷ lệ diện tích |
|---|---|---|
| `#5680E9` | `color.brand.primary` | 10–15% |
| `#8860D0` | `color.brand.accent` | 3–5% |
| `#5AB9EA` | `color.brand.secondary` | 5–10% |
| `#84CEEB` | `color.brand.highlight` | có chọn lọc |
| `#C1C8E4` | `color.brand.muted` | có chọn lọc |

Khoảng 75% diện tích là nền trung tính (canvas `#FCFDFF`, chữ ink `#22283A`).
`#84CEEB` và `#C1C8E4` **không** dùng làm màu chữ. Chữ và nền nút dùng bậc
600–700 của thang (nút/link `#3F67D1`) vì màu gốc không đạt AA.

Typography: **Inter** 400/500/600, số tiền dùng chữ số tabular. Icon:
**`lucide_icons_flutter` 4.0.1**. Chi tiết ở [design-system.md](design-system.md).

## Splash mobile — MOB-P1-010

Copy splash được chốt riêng: **FREEVA** / *Your money. Your freedom.* (giữ
nguyên ở vi/en). Tagline trên board và các asset gốc vẫn giữ nguyên.
Splash Flutter dài 1,8 giây trên gradient brand toàn màn hình: mảnh tím xuất
hiện trước, mảnh cyan trượt lên nhẹ, mảnh xanh hoàn thiện F; halo nhẹ rồi
thu nhỏ 4,5% và fade out sang home. Dùng mask theo khoảng trong suốt trên PNG
gốc, không vẽ lại symbol. Khi bật giảm chuyển động, hiển thị logo/copy tĩnh
và vẫn chuyển màn sau 1,8 giây.

Tinh chỉnh theo ảnh tham chiếu splash: gradient nhiều lớp sáng ở góc trên phải
và vùng trung tâm, tím ở góc dưới trái; symbol lớn theo chiều rộng màn hình,
halo mềm và hai vòng cung mờ. Wordmark navy giãn chữ, tagline đứng màu text
muted; mọi màu lấy từ token hiện có. Giữ nguyên PNG và motion 1,8 giây.
