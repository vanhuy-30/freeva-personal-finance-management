# Phase 1 — tasks (MVP)

## Architecture / tooling

### DOC-P1-001 — Tổng hợp architecture và khóa Flutter toolchain
- Status: done
- Module: docs, mobile, CI
- DoD: có một trang current-state cho tech stack/architecture; Flutter được khóa cùng version ở FVM, pubspec và CI; lệnh Make dùng FVM nhất quán.
- Verification: Flutter `3.47.0` / Dart `3.13.0`; `flutter analyze` sạch; 38 tests pass; CI YAML hợp lệ.

## Brand / shell

### MOB-P1-010 — Brand asset: app icon + splash/symbol
- Status: done
- Module: DS
- Depends: `docs/brand/freeva-app-icon.png`, `freeva-brand-symbol.png` (board [ui-design-system.png](../docs/brand/ui-design-system.png))
- DoD: iOS/Android launcher icon từ `freeva-app-icon.png`; splash (và chỗ brand placeholder) dùng `freeva-brand-symbol.png` đúng tỷ lệ — không icon generic; text/tagline theo [thiết kế splash đã chốt](../docs/brand/README.md#splash-mobile--mob-p1-010), qua l10n; `flutter analyze` sạch; không hardcode hex
- Note: `MOB-P0-002` chỉ theme/token; task này gắn logo thật. Adaptive icon Android + AppIcon iOS.
- Verification: `flutter analyze` sạch; `flutter test` pass; kiểm tra kích thước PNG và iOS không alpha. Hướng dẫn tái sinh và giới hạn kiểm tra native: [mobile README](../apps/mobile/README.md#brand-asset--mob-p1-010).

### WA-P1-001 — Brand asset: favicon + logo shell admin
- Status: done
- Module: 26, DS
- Depends: `docs/brand/freeva-app-icon.png`, `freeva-logo-lockup.png` / `freeva-brand-symbol.png`
- DoD: favicon (và metadata icon) từ app icon; chrome admin (header/sidebar placeholder) dùng lockup hoặc symbol — không chữ “Freeva” thuần thay logo; vẫn chỉ màu qua CSS variables; không dashboard kinh doanh
- Note: `WA-P0-001` chỉ CSS variables; task này gắn asset từ board.
- Verification: `pnpm --filter @freeva/web-admin lint`, `pnpm --filter @freeva/web-admin exec tsc --noEmit`, `pnpm --filter @freeva/web-admin exec next build --webpack` pass.

## Auth / profile

### BE-P1-001 — Đăng ký, login email, verify email, reset password
- Status: done
- Module: 1
- DoD: `/api/v1/auth` register/login/verify/reset; Argon2id; token single-use/expiry; SMTP outbox mã hóa và retry; DTO/OpenAPI/error envelope khớp; audit transaction và log không PII.
- Verification: API build + 37 unit tests + 12 HTTP/PostgreSQL integration tests pass; fresh/upgrade/collision migration pass; SMTP verify/reset qua Mailhog thật pass; OpenAPI validator pass.
- Note: [ADR 009](../docs/architecture/adr/009-email-auth-sessions.md). Cần cấu hình AUTH_SECRET_KEY/SMTP và apply migration trước deploy; chưa deploy staging. Existing dependency audit còn cảnh báo, theo threat model / SEC-P1-001.

### BE-P1-002 — Session, rate limit login, revoke
- Status: done
- Module: 1, 22
- DoD: opaque Bearer 7 ngày, list/revoke own sessions/logout/revoke all; PostgreSQL atomic rate limit IP/email + Retry-After; reset thu hồi toàn bộ, guard fail closed.
- Verification: integration pass ownership/expiry/replay, registration/verify/reset concurrency, shared counters, audit failure rollback; CI có PostgreSQL service và integration job.
- Note: Không refresh token ở scope này; request đã qua guard có thể hoàn thành khi revoke. Không trust X-Forwarded-For mặc định; deployment sau proxy cần review topology (ADR 009).

### MOB-P1-001 — Màn auth + PIN/biometric lock
- Status: doing
- Module: 1, 22
- Depends: BE-P1-001, BE-P1-002
- DoD: email login/register/verify/reset; secure opaque session; PIN 6 số + biometric opt-in; lifecycle lock/privacy cover; list/revoke/logout; l10n vi/en; Clean Architecture + MVVM + abstract DI.
- Verification: Flutter analyze sạch; 33 unit/widget tests pass; Android debug APK (JDK 17), iOS simulator build + cold launch login/Keychain pass.
- Note: [Thiết kế/cấu hình và residual](../docs/architecture/mobile-auth.md). Unlock cần mạng để kiểm tra revoke. Chưa đóng task: cần E2E Resend trên staging và Face ID/fingerprint/recents thiết bị thực. [Runbook email](../docs/infrastructure/email.md).

### MOB-P1-002 — Hồ sơ: locale, currency, TZ, kỳ tài chính
- Status: done
- Module: 2, 24
- Depends: BE-P1-001, BE-P1-002; auth gate của MOB-P1-001.
- DoD: màn hồ sơ vi/en; locale toàn app sau lưu; currency từ catalog, IANA TZ, ngày kỳ 1–28; GET/PUT profile theo session owner và OpenAPI; lưu version chống ghi đè; loading/error/retry; không rò dữ liệu khi lock/logout.
- Verification: Flutter analyze sạch; 50 Flutter tests, 82 API tests, 14 PostgreSQL integration tests và API build pass; gồm persistence/ownership/concurrent 200–409/revoked session.
- Note: [Thiết kế và giới hạn](../docs/architecture/mobile-profile.md). Deploy backend trước mobile; chưa smoke native/E2E staging. Không migration mới; catalog mới hiện có VND, không tự thêm tiền tệ hay quy đổi dữ liệu.

### BE-P1-003 — Google/Apple OAuth (Should)
- Status: done
- Module: 1
- Depends: BE-P1-001, BE-P1-002
- DoD: Google/Apple ID token verification; challenge single-use/provider-bound; identity theo provider+subject, không auto-link email; opaque session/revoke; audit atomic; OpenAPI/DTO, env và log redaction.
- Verification: API unit và 19 HTTP/PostgreSQL integration tests pass; build/TypeScript/OpenAPI pass; fresh migration và upgrade bảo toàn User/session/financial BigInt pass.
- Note: [ADR 010](../docs/architecture/adr/010-google-apple-oauth.md). Cần apply migration và cấu hình client ID allowlist trước khi bật provider; chưa mobile SDK/UI, live provider smoke, explicit linking/recovery hay provider revocation notification.

## Ví / GD / danh mục

### BE-P1-004 — CRUD financial accounts + số dư ban đầu
- Status: done
- Module: 3
- DoD: CRUD bốn loại ví theo session owner; số dư string/bigint derived; cấu hình thẻ, sortOrder, archive/restore; khóa type/currency sau khi có giao dịch; version và clientId chống ghi đè/trùng; DTO/OpenAPI khớp, log không dữ liệu tài chính.
- Verification: 117 unit/HTTP tests và 33 HTTP/PostgreSQL integration tests pass; API build, fresh migration vào DB disposable và OpenAPI validation pass. Bao gồm race create/update và đọc số dư cùng snapshot khi commit đồng thời.
- Note: [Thiết kế API](../docs/architecture/financial-accounts.md), [lệnh test](../backend/api/test/README.md#financial-accounts--be-p1-004). Không thêm migration; chưa deploy staging. UI ví, writer giao dịch và sync thuộc task riêng.

### MOB-P1-003 — UI ví, sắp xếp, ẩn
- Status: done
- Module: 3
- Depends: BE-P1-004, MOB-P1-001
- DoD: danh sách/tạo/sửa bốn loại ví và cấu hình thẻ; số tiền BigInt theo currency catalog; sắp xếp, ẩn/khôi phục qua API với version; l10n vi/en, DI abstract, privacy gate và loại bỏ response cũ sau khóa.
- Verification: Flutter analyze sạch; toàn bộ 61 Flutter tests pass (11 tests mới), gồm int64/derived balance, phân trang, reorder một phần, retry/clientId, conflict và session lifecycle; editor 320px/text scale 2 không overflow.
- Note: [Thiết kế và giới hạn](../docs/architecture/mobile-wallets.md). Reorder dùng PATCH tuần tự do API chưa có batch nguyên tử; lỗi yêu cầu tải lại. Chưa native build/E2E staging trong task này.

### BE-P1-005 — CRUD transactions thu/chi/transfer balanced
- Status: done
- Module: 4
- Depends: BE-P1-004, QA-P0-001
- DoD: CRUD thu/chi/transfer nguyên tử, signed bigint, FX manual exact với quote bất biến; soft-delete/restore cả cặp, owner/session, version, Idempotency-Key/clientId; danh mục chi bắt buộc, notes/tags, lọc/phân trang; DTO/OpenAPI/error envelope và log không PII.
- Verification: 145 unit/HTTP tests và 51 HTTP/PostgreSQL integration tests pass; build, fresh migration vào DB disposable và OpenAPI validation pass. Bao gồm rollback lỗi leg thứ hai khi tạo/sửa/xóa, replay/create/update race và snapshot ví cũ khi ghi giao dịch đầu tiên.
- Note: [Thiết kế API](../docs/architecture/transactions.md), [lệnh test](../backend/api/test/README.md#transactions--be-p1-005). FX cần rounding bị từ chối; list đếm leg. Không migration mới; chưa deploy staging. UI giao dịch, quản lý danh mục, báo cáo và sync thuộc task riêng.

### MOB-P1-004 — Ghi giao dịch < số bước tối thiểu
- Status: todo
- Module: 4

### BE-P1-006 — Categories mặc định VN + custom + ẩn/xóa chuyển GD
- Status: todo
- Module: 5

### MOB-P1-005 — UI danh mục
- Status: todo
- Module: 5

## Báo cáo / search / settings / help

### BE-P1-007 — Báo cáo thu chi, theo danh mục/ví, net worth hiện tại
- Status: todo
- Module: 14

### MOB-P1-006 — Màn tổng quan + báo cáo lọc kỳ
- Status: todo
- Module: 14

### BE-P1-008 — Search cơ bản + không dấu (Should)
- Status: todo
- Module: 19

### MOB-P1-007 — Settings theme/locale/quyền + onboarding + FAQ + feedback
- Status: todo
- Module: 24, 25

## Sync / privacy / security phát hành

### BE-P1-009 — Sync queue, idempotency, chống trùng đơn giản
- Status: todo
- Module: 20
- Depends: BE-P0-001

### MOB-P1-008 — Hàng đợi offline + trạng thái sync
- Status: todo
- Module: 20

### BE-P1-010 — Export JSON + xóa tài khoản
- Status: todo
- Module: 21

### MOB-P1-009 — Ẩn số dư khi nền; thông báo thiết bị mới (Should)
- Status: todo
- Module: 22

### INF-P1-001 — Crash monitoring staging
- Status: todo
- Module: 26
- Note: Residual Phase 0 (2026-09-21): vendor dự kiến Sentry (DECISIONS-OPEN #9); chưa SDK. Gắn API ± admin ± mobile trên staging, scrub PII, smoke event — không chặn đóng P0.

### SEC-P1-001 — Security test cơ bản trước store
- Status: todo
- Module: 22
