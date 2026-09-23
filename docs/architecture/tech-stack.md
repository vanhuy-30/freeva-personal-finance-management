# Tech stack & architecture

> Trang kiểm tra nhanh và chỉnh sửa tập trung cho tech stack và kiến trúc hiện tại của Freeva.
>
> **Trạng thái:** current state · **Cập nhật:** 2026-09-23

Khi thay đổi công nghệ hoặc boundary kiến trúc, cập nhật trang này trong cùng PR. Nếu thay đổi là quyết định khó đảo ngược hoặc ảnh hưởng nhiều phần, tạo/cập nhật ADR tương ứng rồi liên kết lại từ đây. Version dependency chính xác vẫn lấy từ `package.json`, `pubspec.yaml` và lockfile.

## Sơ đồ tổng thể

```text
Mobile (Flutter) ───────┐
                       ├── OpenAPI contract ──> API (NestJS) ──> PostgreSQL
Web Admin (Next.js) ───┘                              │
                                                     └── Redis (queue/cache/session khi triển khai)

Design tokens ─────────────> Mobile + Web Admin
```

- Một backend API phục vụ cả mobile và web admin; admin dùng quyền `staff`.
- `packages/api-contracts/openapi.yaml` là source of truth cho public API.
- Domain không phụ thuộc UI framework, HTTP framework hoặc Prisma.
- Dữ liệu tài chính phải ưu tiên tính đúng đắn, khả năng tái tạo và quyền riêng tư.

## Technology pool

| Khu vực | Công nghệ | Trạng thái | Vai trò / ghi chú |
|---|---|---|---|
| Monorepo | pnpm workspace, Makefile | Adopted | Quản lý JS/TS packages và lệnh phát triển chung; Flutter nằm ngoài pnpm. Không dùng Nx/Turborepo nếu chưa có ADR mới. |
| Mobile | Flutter `3.47.0` qua FVM, Dart `3.13.0` | Adopted | Version được khóa ở `.fvmrc`, `pubspec.yaml` và CI; ứng dụng người dùng cuối cho iOS và Android, không dùng cho web admin. |
| Mobile architecture | Clean Architecture, MVVM, feature-first | Adopted | Mỗi feature tách `data`, `domain`, `presentation`. |
| Mobile DI/state flow | `get_it`, `injectable`, ViewModel | Adopted | View kết nối ViewModel qua DI; ViewModel gọi use case. |
| Mobile domain result | `dartz` `Either<Failure, T>` | Adopted | Chuẩn kết quả giữa domain và data. |
| Mobile navigation/network | `go_router`, `http` | Adopted | Router và HTTP client hiện tại. |
| Mobile security | `flutter_secure_storage`, `local_auth`, `cryptography` | Adopted | Session an toàn, PIN/biometric và crypto phía thiết bị. |
| Backend | NestJS, TypeScript | Adopted | API duy nhất, module theo feature. |
| ORM/database | Prisma, PostgreSQL 16 | Adopted | PostgreSQL là source of truth; Prisma chỉ xuất hiện ở infrastructure. |
| Validation/security | `class-validator`, `class-transformer`, Helmet | Adopted | DTO phải khớp OpenAPI; `ValidationPipe` global. |
| Logging | Pino / `nestjs-pino` | Adopted | JSON log và redact PII. Không log số dư, số tài khoản, email đầy đủ hoặc token. |
| Password/auth | Argon2id, opaque Bearer session | Adopted | User auth/session thuộc `/api/v1`; staff P0 hiện dùng credential env giới hạn. |
| Web admin | Next.js App Router, React, TypeScript | Adopted | Công cụ nội bộ; Server Components mặc định. |
| Web styling | Tailwind CSS, CSS variables từ design tokens | Adopted | Không hardcode màu hex trong component. |
| API contract | OpenAPI YAML | Adopted | Sửa contract trước hoặc cùng PR với Nest DTO/client mapping. |
| Design system | JSON design tokens | Adopted | Nguồn màu brand/semantic dùng chung cho mobile và admin. |
| Cache/queue/session | Redis | Planned | Có trong local compose; chỉ đưa vào luồng nghiệp vụ khi use case tương ứng được triển khai. |
| Email local | Mailhog | Adopted for local | Không phải dịch vụ production. |
| Crash monitoring | Sentry | Proposed | Vendor dự kiến; chưa gắn SDK, theo `INF-P1-001`. |
| Analytics | Typed internal catalog | Adopted foundation | Hiện dùng debug logger local; chưa chọn vendor SDK. |

## Kiến trúc theo phần

### Mobile — `apps/mobile`

```text
lib/
  core/                         # config, DI, router, theme, l10n, logging, network
  features/{feature}/
    data/                       # datasource, model, mapper, repository implementation
    domain/                     # entity, repository abstraction, use case
    presentation/               # page, widget, ViewModel
```

Boundary bắt buộc:

- `domain` không import Flutter, `dart:ui` hoặc implementation từ data.
- View chỉ xử lý UI, không gọi repository; ViewModel giữ state và gọi use case.
- Consumer phụ thuộc repository abstraction được đăng ký qua DI.
- Chuỗi hiển thị dùng l10n `S`; màu dùng theme/design tokens.
- Không dùng `double` cho tiền và không dùng `print()` cho logging.
- Widget dài hơn 100 dòng nên tách vào `presentation/widgets/`.
- Test trọng tâm: use case và ViewModel; luồng auth/sync quan trọng cần integration/E2E phù hợp.

### Backend — `backend/api`

```text
src/
  core/                         # logging, money và concern dùng chung
  infrastructure/              # Prisma và adapter hạ tầng chung
  modules/{feature}/
    domain/                     # rule/entity/repository abstraction
    dto/                        # request/response validation
    infrastructure/            # repository/provider implementation
```

Boundary bắt buộc:

- Module tổ chức theo feature; domain/application không phụ thuộc Prisma.
- Public endpoint phải có trong OpenAPI trước hoặc cùng PR với implementation.
- DTO dùng `class-validator` và phải khớp contract.
- Tiền dùng integer minor units (`BigInt`) hoặc `Decimal`, tuyệt đối không dùng `Float`.
- Transfer được ghi bằng hai leg cân bằng trong một use case/transaction có kiểm soát.
- PII phải được redact ở logger; auth, ownership và role được kiểm tra fail-closed.
- Health endpoint chuẩn là `GET /api/health`.

### Web admin — `apps/web-admin`

- Dùng Next.js App Router; ưu tiên Server Components, chỉ dùng Client Components khi cần tương tác hoặc browser API.
- Truy cập dữ liệu qua backend API; không kết nối trực tiếp database.
- Base URL lấy từ `NEXT_PUBLIC_API_BASE_URL`.
- Màu lấy từ CSS variables sinh từ design tokens; không hardcode hex.
- Không đưa full PII vào client log, analytics hoặc query string.
- Mọi chức năng nhạy cảm phải kiểm tra quyền `staff` ở backend; kiểm tra phía UI không phải security boundary.
- Staff auth P0 hiện là opaque Bearer credential từ env và một actor UUID. Identity/session/revoke cho nhiều staff phải thay thế cơ chế này trước production.

### Shared packages

| Package | Trách nhiệm | Quy tắc |
|---|---|---|
| `packages/api-contracts` | OpenAPI public contract | Là source of truth; thay đổi contract đi cùng DTO và cập nhật client. |
| `packages/design-tokens` | Brand và semantic colors | Mobile/admin chỉ consume token; không tạo màu rời trong UI. |

## Quy ước dữ liệu và API

- Base API là `/api`; endpoint versioned dùng `/api/v1` khi cần ổn định/breaking evolution.
- Error envelope chuẩn: `{ "error": { "code", "message", "details" } }`.
- Money field public dùng string integer `amountMinor` kèm `currency`.
- POST tạo giao dịch dùng `Idempotency-Key`.
- Tiền trong database dùng integer minor units; VND có `minorDigits = 0`.
- Số dư được suy ra từ `initialBalanceMinor` và giao dịch chưa xóa; chưa cache balance.
- Transfer gồm hai transaction cùng `transferGroupId`; nguồn âm, đích dương.
- FX phải lưu rate và thời điểm để báo cáo có thể tái tạo.
- Record do user sở hữu dùng UUID, `clientId`, version tăng đơn điệu và timestamps.
- Offline MVP hiện định hướng mutation queue + exponential retry, không dùng CRDT; conflict giao dịch cần server resolution và review khi amount khác.

Chi tiết model/invariant: [Data model](data-model.md), [Money & FX ADR](adr/006-money-and-fx.md), [Sync](sync.md).

## Môi trường và vận hành

| Environment | Runtime / hosting | Dữ liệu |
|---|---|---|
| Local | Docker Compose: PostgreSQL, Redis, Mailhog; API `:4000`; admin `:3001` | Chỉ dữ liệu dev. |
| Test/CI | Node + Flutter jobs; PostgreSQL service container khi cần | Fixture/test data. |
| Staging | Render: API + PostgreSQL; Vercel: web admin | Isolated/seed data, không dùng PII thật. |
| Production | Region dữ liệu primary: Việt Nam | Vendor hosting chưa chốt; phải hoàn tất security, backup/PITR và observability trước Store. |

## Các quyết định còn mở

| Chủ đề | Hiện trạng | Điều kiện chốt |
|---|---|---|
| Production hosting | Vendor chưa chọn; region Việt Nam đã chốt | Trước khi chuẩn bị phát hành Store. |
| Offline conflict | Queue + retry, không CRDT là phương án hiện tại | Chốt cùng thiết kế/implementation sync Phase 1. |
| Redis responsibility | Dự kiến queue/cache/session | Mỗi use case phải có owner, TTL/durability và failure policy trước khi dùng. |
| FX/bank/market provider | FX nhập tay ở MVP; external partner để sau | Khi vào scope tích hợp Phase 6. |
| Crash monitoring | Dự kiến Sentry, chưa tích hợp | `INF-P1-001`. |
| Analytics vendor | Chưa chọn | Khi cần gửi production telemetry; phải qua privacy review. |
| Multi-staff identity | P0 mới có single staff credential | Bắt buộc trước production admin. |
| Production backup/PITR | Chưa triển khai đầy đủ | Chốt RPO/RTO, retention và restore drill trước production. |

Danh sách quyết định vận hành mới nhất được theo dõi tại [DECISIONS-OPEN](../project-state/DECISIONS-OPEN.md).

## Checklist khi thay đổi stack/architecture

- [ ] Cập nhật hàng tương ứng trong trang này và ngày `Cập nhật`.
- [ ] Tạo ADR nếu thay đổi khó đảo ngược, đổi boundary hoặc ảnh hưởng từ hai phần trở lên.
- [ ] Cập nhật OpenAPI nếu public contract thay đổi.
- [ ] Kiểm tra money, transfer, PII, auth/ownership và data residency.
- [ ] Cập nhật manifest/lockfile và tài liệu môi trường liên quan.
- [ ] Bổ sung test ở layer chịu trách nhiệm, không test xuyên boundary chỉ để né abstraction.
- [ ] Gắn Task ID đúng format vào PR/commit.

## ADR nền tảng

- [001 — Monorepo](adr/001-monorepo.md)
- [002 — Flutter](adr/002-flutter.md)
- [003 — NestJS](adr/003-nestjs.md)
- [004 — Next.js admin](adr/004-next-admin.md)
- [005 — PostgreSQL](adr/005-postgres.md)
- [006 — Money and FX](adr/006-money-and-fx.md)
- [007 — Core data model](adr/007-core-data-model.md)
- [008 — Audit event schema](adr/008-audit-event-schema.md)
- [009 — Email auth and sessions](adr/009-email-auth-sessions.md)
