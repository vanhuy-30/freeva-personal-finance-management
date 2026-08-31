# Palette

Nguồn sự thật: [packages/design-tokens/tokens.json](../../packages/design-tokens/tokens.json). Mood tham chiếu: [reference.png](reference.png) (gradient xanh–tím). Không copy UI Facebook/Timelikes.

## Brand (user chốt)

| Token | Hex | Dùng | Không dùng |
|---|---|---|---|
| `color.brand.primary` | `#5680E9` | CTA, link, focus, tab active | Nền chữ nhỏ nếu contrast fail |
| `color.brand.secondary` | `#5AB9EA` | Chip, info, icon phụ | Chữ body |
| `color.brand.highlight` | `#84CEEB` | Gradient end, splash wash | **Chữ** |
| `color.brand.muted` | `#C1C8E4` | Border, divider, surface tint | **Chữ** |
| `color.brand.accent` | `#8860D0` | Logo, accent bar | Nền full-bleed chữ nhỏ |

Gradient CTA/splash: `#5680E9` → `#5AB9EA` (tuỳ chỗ thêm `#8860D0`).

## Neutral (bắt buộc, ngoài board)

- Text: `#1B1F3B`
- Text muted: `#5C6378`
- Surface: `#FFFFFF`
- Canvas: `#F4F6FB`
- On-primary: `#FFFFFF`

## Semantic tài chính

- `success` (thu): `#2F9E76`
- `danger` (chi): `#D64545`
- `warning`: `#D4A017`

Không nhuộm primary thành đỏ/lục.

## Dark

Cùng brand hue. Canvas `#12141F`, surface `#1B1F33`, text `#F4F6FB`. Contrast WCAG AA.
