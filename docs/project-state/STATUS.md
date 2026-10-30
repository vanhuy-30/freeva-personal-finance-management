# STATUS

- **Phase hiện tại:** 2 — Phase 0 **closed** 2026-09-21; Phase 1 **closed** 2026-10-21 (gate sổ cái). Chưa phải product v1 — còn ngân sách / mục tiêu / insight (`Gate: v1` ở phase sau). Đối chiếu spec: [spec-alignment.md](../product/spec-alignment.md).
- **Cập nhật:** 2026-10-30
- **Việc bổ sung Phase 2:** `BE-P2-010` khóa kind lúc ghi; `INF-P2-001` Postgres staging miễn phí (DB Render free đã hết hạn); `MOB-P2-011` xuất/xóa tài khoản trên app; `QA-P2-001` rà hàng đợi offline; `BE-P2-012` câu trả lời đầu gắn tài khoản; `BE-P2-013` quy đổi để hiển thị; `BE-P2-014` mật khẩu tối thiểu 8 + kiểm tra email trên app. Chi tiết: [tasks/phase-02.md](../../tasks/phase-02.md).
- **CI:** `INF-P0-002` done; cả ba job xanh trên `main`, [run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189).
- **Staging:** API [Render](https://freeva-api-staging.onrender.com) và admin [Vercel](https://freeva-personal-finance-management.vercel.app) đã xanh ngày 2026-09-21. Postgres free trên Render đã hết hạn — chuyển DB: `INF-P2-001`. Prod hoster TBD tới Store (region VN).
- **Crash monitoring:** `INF-P1-001` done — Sentry trên API, admin và mobile; tắt khi không có DSN; scrub PII. Event live chờ DSN trên dashboard (DECISIONS-OPEN #9, [ADR 011](../architecture/adr/011-sentry-crash-monitoring.md)).
- **Brand:** board + PNG trong `docs/brand/`; token/theme P0 done. Mobile `MOB-P1-010` done: launcher iOS/Android + symbol splash/home và l10n tagline. Admin `WA-P1-001` done: favicon từ app icon và lockup ở header.
- **Transfer QA:** `QA-P0-002` done; fixture JSON versioned + contract test cho cùng currency và FX exact. `BE-P1-005` dùng evaluator production và thêm fixture; chỉ nhận FX exact, không làm tròn ngầm.
- **Audit:** `BE-P0-004` schema done; `WA-P0-002` ghi `staff.user_lookup`; `BE-P1-010` ghi `user.data_export` và `user.account_delete` fail closed. Bảng chưa append-only.
- **Staff lookup:** `WA-P0-002` done; exact email/UUID, response hồ sơ tối thiểu, opaque Bearer env + actor UUID, không dashboard/dữ liệu tài chính. Auth single-staff P0 phải thay trước production.
- **Mobile auth:** `MOB-P1-001` done (2026-10-19): email auth, secure session, PIN/biometric lock, privacy cover và quản lý phiên. Analyze + 33 tests + native builds pass; Face ID/fingerprint/recents pass trên thiết bị thực. Residual: E2E Resend staging hoãn đến khi setup Resend. [Email runbook](../infrastructure/email.md). [Chi tiết](../architecture/mobile-auth.md).
- **Mobile profile:** `MOB-P1-002` done: locale/currency/IANA TZ/kỳ 1–28, API theo owner với version chống ghi đè, l10n và privacy gate. Analyze, Flutter tests, API build/tests và PostgreSQL integration pass. Chưa deploy/smoke native. [Chi tiết](../architecture/mobile-profile.md).
- **Mobile wallets:** `MOB-P1-003` done: danh sách/tạo/sửa bốn loại ví, tiền BigInt, sắp xếp/ẩn/khôi phục, version/clientId và privacy gate. Analyze và 11 tests mới pass; chưa native build/E2E staging. [Chi tiết](../architecture/mobile-wallets.md).
- **Mobile transactions:** `MOB-P1-004` done: ghi thu/chi/chuyển ít bước, tiền BigInt, FX exact, ngày theo TZ, version/clientId và privacy gate. `QA-P1-001` done: composer sớm, autofocus số tiền, ghim Lưu; analyze và 135 tests pass; bấm giờ thiết bị thật gom smoke phase. [Chi tiết](../architecture/mobile-transactions.md).
- **Mobile categories:** `MOB-P1-005` done: danh sách cây, tạo/sửa custom, màu/icon catalog, ẩn/khôi phục và xóa kèm chuyển giao dịch. Analyze và 10 tests mới pass; chưa native build/E2E staging. [Chi tiết](../architecture/mobile-categories.md).
- **Mobile reports:** `MOB-P1-006` done: tổng quan tài sản/nợ/ròng và thu chi tháng này, báo cáo lọc tuần/tháng/khoảng, mỗi loại tiền một khối. Analyze và 14 tests mới pass; chưa native build/E2E staging. [Chi tiết](../architecture/mobile-reports.md).
- **Mobile settings:** `MOB-P1-007` done: theme sáng/tối/hệ thống trên thiết bị, lối sang hồ sơ, cờ sinh trắc, onboarding một lần, FAQ, phản hồi chỉ sao chép, phiên bản và bản nháp ToS/privacy. Analyze và 14 tests mới pass (108 tổng); chưa native build/E2E staging. [Chi tiết](../architecture/mobile-settings.md).
- **Mobile sync:** `MOB-P1-008` done: hàng đợi mutation giao dịch khi mất mạng, gửi lại bằng `POST /api/v1/sync`, conflict không ghi đè. Analyze và 9 tests mới pass (117 tổng); chưa native build/E2E staging. [Chi tiết](../architecture/mobile-sync.md).
- **Mobile privacy:** `MOB-P1-009` done: nút mắt che số đang đọc, cảnh báo phiên đăng nhập mới bằng banner và thông báo cục bộ. Analyze và 13 tests mới pass (130 tổng); chưa native build/E2E staging. [Chi tiết](../architecture/mobile-privacy.md).
- **Mobile merchant/tags:** `MOB-P1-011` done: merchant trên thu/chi, gắn/gỡ nhãn. Analyze và 137 Flutter tests pass; chưa native build/E2E staging. [Chi tiết](../architecture/mobile-tags.md).
- **Quy đổi hiển thị:** `BE-P2-013` / `MOB-P2-013` done 2026-10-30: tỷ giá người dùng nhập (`UserFxRate`), tiền tệ hiển thị lưu trên tài khoản, Tổng quan cộng tài sản/nợ/ròng/thu/chi đã quy đổi, chi tiết ví và giao dịch hiện số quy đổi kèm tỷ giá. Chỉ hiển thị; báo cáo kỳ vẫn tách từng loại tiền. [ADR 006](../architecture/adr/006-money-and-fx.md).
- **Onboarding/tài khoản (nhóm A):** `DS-P2-004` done 2026-10-29: 16 màn khớp canvas, ngân sách nối `BE-P2-E02`, mục tiêu Nợ đưa khối Thẻ tín dụng lên đầu. `BE-P2-012` done 2026-10-30. Còn tách riêng: deep link email, Google/Apple mobile, xác nhận lại email trong Cá nhân. [Chi tiết](../brand/patterns/A-onboarding-auth.md).
- **Mobile analytics:** `MOB-P0-004` done; catalog typed, debug logger local, `schema_version: 1`, không property tùy ý/PII và chưa có vendor SDK.
- **Backup/restore:** `BE-P0-005` done; [runbook và bằng chứng local](../../infra/runbooks/backup-restore.md), PostgreSQL 16.14. Production PITR/retention/RPO/RTO chưa triển khai.
- **Scaffold:** xong trên `main` (`153d3e7`). Health API, admin placeholder, Flutter shell, docs, compose.
- **Auth API:** `BE-P1-001` / `BE-P1-002` done; `BE-P1-003` Google/Apple ID token backend done — chưa mobile SDK/UI, chưa live provider smoke.
- **Financial accounts:** `BE-P1-004` done: CRUD bốn loại ví, số dư derived bigint, credit config, sắp xếp/lưu trữ/khôi phục, owner/version/clientId; 117 unit và 33 PostgreSQL integration tests, build/OpenAPI pass. Không migration mới; chưa deploy staging. [Thiết kế](../architecture/financial-accounts.md).
- **Transactions:** `BE-P1-005` done: CRUD thu/chi/transfer nguyên tử, FX exact/quote bất biến, soft-delete/restore cả cặp, owner/version/Idempotency-Key/clientId, category/tags/filter. 145 unit/HTTP + 51 PostgreSQL tests, build/OpenAPI pass; không migration, chưa deploy staging. [Thiết kế](../architecture/transactions.md).
- **Categories:** `BE-P1-006` / `BE-P1-011` done: bộ VN, custom, `kind`, supplement một lần. Migration additive cần deploy trước API. [Thiết kế](../architecture/categories.md).
- **Reports / search:** `BE-P1-007` / `BE-P1-008` / `BE-P2-E06` / `BE-P2-E08` done (cashflow so kỳ + savings rate + top merchant; `GET /reports/series`; `GET /reports/month-review`). Chưa deploy staging.
- **Tags / merchant:** `BE-P1-012` done. Migration `transaction_merchant`; chưa deploy staging. [Thiết kế](../architecture/tags.md).
- **Sync queue:** `BE-P1-009` done: `POST /api/v1/sync` áp hàng đợi giao dịch, idempotent theo `clientId`, conflict không ghi đè, gợi ý trùng 10 phút. 19 unit suites / 179 tests và 6 PostgreSQL suites / 75 tests, build/OpenAPI pass. Một migration seed `SchemaMeta`. Chưa deploy staging. [Thiết kế](../architecture/sync.md).
- **Export / xóa tài khoản:** `BE-P1-010` done: `GET /api/v1/account/export` và `DELETE /api/v1/account`, audit fail closed, UUID audit được giữ. 20 unit suites / 185 tests và 7 PostgreSQL suites / 79 tests, build/OpenAPI pass. Không migration. Chưa deploy staging. [Thiết kế](../architecture/account-privacy.md).
- **Security Phase 1:** `SEC-P1-001` done ([security-test-phase1.md](../architecture/security-test-phase1.md)); residual `deepmerge-ts` trong Prisma, audit chưa append-only, luật sư trước store.
- **Data model:** `BE-P0-001` xong (ADR 007, Prisma lõi). CRUD ví đã có ở `BE-P1-004`; CRUD giao dịch đã có ở `BE-P1-005`.
- **Threat model:** `SEC-P0-001` xong ([threat-model.md](../architecture/threat-model.md)).
- **PII logs:** `SEC-P0-003` xong ([pii-log-checklist.md](../architecture/pii-log-checklist.md)).
- **Personas / use case ghi chi:** `PRD-P0-001` xong ([personas.md](../product/personas.md), [use-cases.md](../product/use-cases.md)).
- **ToS / privacy nháp:** `PRD-P0-002` xong ([terms-of-service.md](../legal/terms-of-service.md), [privacy-policy.md](../legal/privacy-policy.md)). Cần luật sư trước store.
- **Region dữ liệu:** chốt **Việt Nam** (DECISIONS-OPEN #5, 2026-09-18). Vendor hosting production cụ thể vẫn TBD tới Store.

## Backlog Phase 0

- **25/25 done.** `INF-P0-004` provision live verified 2026-09-21.

Chi tiết status từng ID: [tasks/phase-00.md](../../tasks/phase-00.md).

## Backlog Phase 1

- **28/28 done.** Gate sổ cái đóng 2026-10-21.

Chi tiết status từng ID: [tasks/phase-01.md](../../tasks/phase-01.md).

## Phase 0 gate — đã đóng (2026-09-21)

Theo [điều kiện hoàn thành Phase 0](../product/phases/phase-00.md) và [DECISIONS-OPEN](DECISIONS-OPEN.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P0 | Done (25/25) |
| Data model + security flow review | Done (ADR 007/008, threat model, PII checklist) |
| Backup/restore thử | Done local (`BE-P0-005`); production PITR chưa |
| Staging cloud | Done — `INF-P0-004`; URL ở mục Staging trên |
| Crash monitoring | SDK staging done (`INF-P1-001`); event live chờ DSN |
| Region dữ liệu | **Chốt VN** — DECISIONS-OPEN #5 (2026-09-18) |
| Logging JSON + redact | Done (`BE-P0-003` / `SEC-P0-003`) |
| PDPD / compliance skeleton | Có docs; luật sư trước store (không chặn foundation nếu chấp nhận nháp) |
| Prototype ghi thu chi với user | Không bắt buộc trong lần foundation này (Phase 1) |

Đóng theo option **B**: `INF-P0-004` xong + residual crash ghi rõ → mở Phase 1.

## Phase 1 gate — đã đóng (2026-10-21)

Theo [điều kiện hoàn thành Phase 1](../product/phases/phase-01.md) và [spec-alignment.md](../product/spec-alignment.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P1 | Done (28/28), gồm toàn bộ `Gate: v1` và Should |
| Onboarding → ví → giao dịch đầu | Done code + unit/widget (`MOB-P1-001`…`004`); E2E staging/native smoke còn residual |
| Số dư đúng sau thu/chi/chuyển/sửa/xóa | Done (`BE-P1-004`, `BE-P1-005`, `MOB-P1-003`, `MOB-P1-004`) |
| Sync không tạo trùng (kịch bản chính) | Done (`BE-P1-009`, `MOB-P1-008`) |
| Báo cáo khớp nguồn | Done (`BE-P1-007`, `MOB-P1-006`); không cộng khác loại tiền |
| Export, xóa TK, reset password, thu hồi phiên | Done (`BE-P1-010`, `BE-P1-001`/`002`, `MOB-P1-001`) |
| Security checklist trước store (skeleton) | Done (`SEC-P1-001`); residual ghi rõ |
| Crash monitoring SDK | Done (`INF-P1-001`); DSN live chờ vận hành |

Đóng theo option **B** (giống Phase 0): backlog + gate sổ cái xong trên `main` + residual vận hành ghi rõ → mở Phase 2.

### Residual chấp nhận (không chặn đóng Phase 1)

- Deploy staging: migration/API Phase 1 (categories `kind`, `SchemaMeta`, merchant, auth/OAuth env) và smoke E2E sau deploy.
- Mobile: native build + E2E staging cho hầu hết màn P1; bấm giờ ghi chi dưới 10 giây (`QA-P1-001`) gom smoke.
- Email: E2E Resend delivery/inbox (`MOB-P1-001`) khi đã setup Resend.
- Sentry: event dashboard khi có DSN (DECISIONS-OPEN #9).
- OAuth: nút Google/Apple trên mobile + live provider smoke (`BE-P1-003` chỉ backend).
- Product v1: ngân sách / mục tiêu / insight vẫn ở Phase 2 / 3 / 5 (`Gate: v1`).
- Store: luật sư ToS/privacy, audit append-only, auth staff production, prod hoster VN.

## Ghi chú

Local: API `:4000`, Postgres compose `:5434`, admin `:3001`. Deploy migration categories / schema meta / merchant trước API khi lên staging.
