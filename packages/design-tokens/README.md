# @freeva/design-tokens

Nguồn duy nhất cho màu, chữ, khoảng cách, bo góc, bóng và chuyển động của Freeva.
Docs: [design-system.md](../../docs/brand/design-system.md), [palette.md](../../docs/brand/palette.md),
[ADR 012](../../docs/architecture/adr/012-design-tokens-v2.md).

| File | Vai trò |
|---|---|
| `tokens.json` | Nguồn. Tầng `primitive` → `semantic` (light/dark) → `component`, cùng `typography`, `space`, `radius`, `size`, `layout`, `border`, `elevation`, `motion`. |
| `tokens.css` | **Sinh ra**, không sửa tay. Biến legacy `--color-brand-*`, `--color-neutral-*` và biến semantic `--color-bg-*`, `--color-text-*`… Dark ở `[data-theme='dark']`. |
| `scripts/build.mjs` | Sinh `tokens.css`. |
| `scripts/build-dart.mjs` | Sinh `apps/mobile/lib/core/theme/tokens.g.dart` (`FreevaColors` light/dark, scale, typography, `categoryPalette`). |
| `scripts/check.mjs` | Kiểm tra tham chiếu, tương phản AA và cấm highlight/muted làm chữ. |

```bash
pnpm --filter @freeva/design-tokens build
pnpm --filter @freeva/design-tokens check
```

Nhánh `color.*` là bảng màu danh mục của API: không đổi hay xoá key.
Không hardcode hex trong `apps/mobile` hay `apps/web-admin`.
