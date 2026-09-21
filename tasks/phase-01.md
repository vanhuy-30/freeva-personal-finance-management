# Phase 1 — tasks (MVP)

## Brand / shell

### MOB-P1-010 — Brand asset: app icon + splash/symbol
- Status: done
- Module: DS
- Depends: `docs/brand/freeva-app-icon.png`, `freeva-brand-symbol.png` (board [ui-design-system.png](../docs/brand/ui-design-system.png))
- DoD: iOS/Android launcher icon từ `freeva-app-icon.png`; splash (và chỗ brand placeholder) dùng `freeva-brand-symbol.png` đúng tỷ lệ — không icon generic; text/tagline theo [thiết kế splash đã chốt](../docs/brand/README.md#splash-mobile--mob-p1-010), qua l10n; `flutter analyze` sạch; không hardcode hex
- Note: `MOB-P0-002` chỉ theme/token; task này gắn logo thật. Adaptive icon Android + AppIcon iOS.
- Verification: `flutter analyze` sạch; `flutter test` pass; kiểm tra kích thước PNG và iOS không alpha. Hướng dẫn tái sinh và giới hạn kiểm tra native: [mobile README](../apps/mobile/README.md#brand-asset--mob-p1-010).

### WA-P1-001 — Brand asset: favicon + logo shell admin
- Status: todo
- Module: 26, DS
- Depends: `docs/brand/freeva-app-icon.png`, `freeva-logo-lockup.png` / `freeva-brand-symbol.png`
- DoD: favicon (và metadata icon) từ app icon; chrome admin (header/sidebar placeholder) dùng lockup hoặc symbol — không chữ “Freeva” thuần thay logo; vẫn chỉ màu qua CSS variables; không dashboard kinh doanh
- Note: `WA-P0-001` chỉ CSS variables; task này gắn asset từ board.

## Auth / profile

### BE-P1-001 — Đăng ký, login email, verify email, reset password
- Status: todo
- Module: 1

### BE-P1-002 — Session, rate limit login, revoke
- Status: todo
- Module: 1, 22

### MOB-P1-001 — Màn auth + PIN/biometric lock
- Status: todo
- Module: 1, 22

### MOB-P1-002 — Hồ sơ: locale, currency, TZ, kỳ tài chính
- Status: todo
- Module: 2, 24

### BE-P1-003 — Google/Apple OAuth (Should)
- Status: todo
- Module: 1

## Ví / GD / danh mục

### BE-P1-004 — CRUD financial accounts + số dư ban đầu
- Status: todo
- Module: 3

### MOB-P1-003 — UI ví, sắp xếp, ẩn
- Status: todo
- Module: 3

### BE-P1-005 — CRUD transactions thu/chi/transfer balanced
- Status: todo
- Module: 4
- Depends: BE-P1-004, QA-P0-001

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
