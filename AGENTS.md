# AGENTS.md — quy tắc cho người và AI làm việc trong repo Freeva

Đây là monorepo quản lý tài chính cá nhân. Ưu tiên **đúng tiền, đúng quyền riêng tư, đúng layer** hơn tốc độ viết code.

## Layout

| Path | Stack | Ghi chú |
|---|---|---|
| `apps/mobile` | Flutter | iOS + Android. Không dùng Flutter cho web admin. |
| `apps/web-admin` | Next.js App Router | Nội bộ, không phải app người dùng cuối. |
| `backend/api` | NestJS + Prisma | API duy nhất. |
| `packages/api-contracts` | OpenAPI YAML | Source of truth cho DTO public. |
| `packages/design-tokens` | JSON | Màu brand. Cấm hex rời trong UI. |
| `docs/` | Markdown | Product + architecture. Đừng nhân bản roadmap ở README. |
| `tasks/` | Markdown | Backlog. Mọi PR nêu task ID. |

## Flutter (`apps/mobile`)

- Feature-based: `lib/features/{feature_name}/{data,domain,presentation}/`.
- Domain: entity, repository abstract, use case. Không import `dart:ui` / `package:flutter`.
- View (page): chỉ UI. Không gọi repository. Kết nối ViewModel qua DI.
- ViewModel: state + gọi use case. Không `material.dart`.
- DI: `get_it` + `injectable`. Đăng ký abstract, không concrete ở chỗ consume.
- Kết quả domain/data: `Either<Failure, Success>` (dartz).
- Không `print()`. Dùng logger trong `lib/core/logging`.
- Không hardcode chuỗi (dùng l10n `S`) hay màu (dùng theme / tokens).
- Widget > 100 dòng: tách file trong `features/{name}/presentation/widgets/`.
- File `snake_case.dart`, class `PascalCase`.

## Tiền và dữ liệu tài chính

- Số tiền: integer minor units (VND = đồng) hoặc `Decimal`. Không `double` / `float`.
- Chuyển khoản: hai leg cân bằng; không “một dòng trừ nguồn cộng đích” không kiểm soát.
- Tỷ giá: lưu rate + thời điểm; báo cáo phải tái tạo được.
- Không log số dư, số tài khoản, email đầy đủ, token.

## Brand / UI

- Chỉ dùng token trong `packages/design-tokens`. Xem `docs/brand/palette.md`.
- `#C1C8E4` và `#84CEEB` không dùng làm màu chữ.
- Light là theme mặc định; dark dùng cùng brand hue, surface navy-tím.

## Backend

- Module Nest theo feature. Domain không phụ thuộc Prisma ở interface.
- Mọi endpoint public nằm trong OpenAPI trước hoặc cùng PR với code.
- Health: `GET /api/health`.
- Che PII trong log. ValidationPipe global.

## Task ID

Format `{PREFIX}-P{phase}-{nnn}`: `BE`, `MOB`, `WA`, `INF`, `DOC`, `SEC`, `DS`, `QA`, `SHD`, `PRD`.

Commit: `feat(MOB-P1-004): …`. Chi tiết: `tasks/README.md`.

## Không làm

- Không bịa timeline, đối tác ngân hàng, hoặc IAP.
- Không thêm Nx/Turborepo trừ khi có ADR mới.
- Không commit secret.
- Không viết exploit / bỏ qua auth “vì local”.
