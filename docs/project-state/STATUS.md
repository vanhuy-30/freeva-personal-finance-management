# STATUS

- **Phase hiện tại:** 5 (sau v1) — Phase 0 **closed** 2026-09-21; Phase 1 **closed** 2026-10-21 (gate sổ cái); Phase 2 **closed** 2026-10-30; Phase 3 **closed** 2026-11-05; Phase 4 **closed** 2026-11-10. Backlog `Gate: v1` đã xong trên `develop`; chưa chạy thử trọn luồng trên thiết bị với backend thật. AI (gợi ý danh mục, insight) ra sau v1 từ 2026-11-02. Đối chiếu spec: [spec-alignment.md](../product/spec-alignment.md).
- **Cập nhật:** 2026-11-11
- **Phạm vi Phase 5 (2026-11-11):** cờ và cấu hình ở server, sửa trên web admin; chuyển các số đang hardcode trong app (Phase 0–4) lên server; gợi ý danh mục, insight, dự báo chi, what-if tính bằng quy tắc. Nhập sao kê ngân hàng bỏ. OCR và Ask Freeva sang Phase 8, chờ chốt hướng AI (DECISIONS-OPEN #12–14).
- **Việc bổ sung Phase 2:** `BE-P2-010` khóa kind lúc ghi; `MOB-P2-011` xuất/xóa tài khoản trên app; `QA-P2-001` rà hàng đợi offline; `BE-P2-012` câu trả lời đầu gắn tài khoản; `BE-P2-013` quy đổi để hiển thị; `BE-P2-014` mật khẩu tối thiểu 8 + kiểm tra email trên app. Chi tiết: [tasks/phase-02.md](../../tasks/phase-02.md).
- **CI:** `INF-P0-002` done; cả ba job xanh trên `main`, [run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189).
- **Môi trường:** chỉ chạy local (Ghi chú cuối file). Chưa có server, domain, tài khoản App Store / Google Play.
- **Crash monitoring:** `INF-P1-001` done — Sentry trên API, admin và mobile; tắt khi không có DSN; scrub PII. [ADR 011](../architecture/adr/011-sentry-crash-monitoring.md).
- **Brand:** board + PNG trong `docs/brand/`; token/theme P0 done. Mobile `MOB-P1-010` done: launcher iOS/Android + symbol splash/home và l10n tagline. Admin `WA-P1-001` done: favicon từ app icon và lockup ở header.
- **Transfer QA:** `QA-P0-002` done; fixture JSON versioned + contract test cho cùng currency và FX exact. `BE-P1-005` dùng evaluator production và thêm fixture; chỉ nhận FX exact, không làm tròn ngầm.
- **Audit:** `BE-P0-004` schema done; `WA-P0-002` ghi `staff.user_lookup`; `BE-P1-010` ghi `user.data_export` và `user.account_delete` fail closed. Bảng chưa append-only.
- **Staff lookup:** `WA-P0-002` done; exact email/UUID, response hồ sơ tối thiểu, opaque Bearer env + actor UUID, không dashboard/dữ liệu tài chính. Auth single-staff P0 phải thay trước production.
- **Mobile auth:** `MOB-P1-001` done (2026-10-19): email auth, secure session, PIN/biometric lock, privacy cover và quản lý phiên. Analyze + 33 tests + native builds pass; Face ID/fingerprint/recents pass trên thiết bị thực. [Email runbook](../infrastructure/email.md). [Chi tiết](../architecture/mobile-auth.md).
- **Mobile profile:** `MOB-P1-002` done: locale/currency/IANA TZ/kỳ 1–28, API theo owner với version chống ghi đè, l10n và privacy gate. Analyze, Flutter tests, API build/tests và PostgreSQL integration pass. [Chi tiết](../architecture/mobile-profile.md).
- **Mobile wallets:** `MOB-P1-003` done: danh sách/tạo/sửa bốn loại ví, tiền BigInt, sắp xếp/ẩn/khôi phục, version/clientId và privacy gate. Analyze và 11 tests mới pass. [Chi tiết](../architecture/mobile-wallets.md).
- **Mobile transactions:** `MOB-P1-004` done: ghi thu/chi/chuyển ít bước, tiền BigInt, FX exact, ngày theo TZ, version/clientId và privacy gate. `QA-P1-001` done: composer sớm, autofocus số tiền, ghim Lưu; analyze và 135 tests pass; bấm giờ thiết bị thật gom smoke phase. [Chi tiết](../architecture/mobile-transactions.md).
- **Mobile categories:** `MOB-P1-005` done: danh sách cây, tạo/sửa custom, màu/icon catalog, ẩn/khôi phục và xóa kèm chuyển giao dịch. Analyze và 10 tests mới pass. [Chi tiết](../architecture/mobile-categories.md).
- **Mobile reports:** `MOB-P1-006` done: tổng quan tài sản/nợ/ròng và thu chi tháng này, báo cáo lọc tuần/tháng/khoảng, mỗi loại tiền một khối. Analyze và 14 tests mới pass. [Chi tiết](../architecture/mobile-reports.md).
- **Mobile settings:** `MOB-P1-007` done: theme sáng/tối/hệ thống trên thiết bị, lối sang hồ sơ, cờ sinh trắc, onboarding một lần, FAQ, phản hồi chỉ sao chép, phiên bản và bản nháp ToS/privacy. Analyze và 14 tests mới pass (108 tổng). [Chi tiết](../architecture/mobile-settings.md).
- **Mobile sync:** `MOB-P1-008` done: hàng đợi mutation giao dịch khi mất mạng, gửi lại bằng `POST /api/v1/sync`, conflict không ghi đè. Analyze và 9 tests mới pass (117 tổng). [Chi tiết](../architecture/mobile-sync.md).
- **Mobile privacy:** `MOB-P1-009` done: nút mắt che số đang đọc, cảnh báo phiên đăng nhập mới bằng banner và thông báo cục bộ. Analyze và 13 tests mới pass (130 tổng). [Chi tiết](../architecture/mobile-privacy.md).
- **Mobile merchant/tags:** `MOB-P1-011` done: merchant trên thu/chi, gắn/gỡ nhãn. Analyze và 137 Flutter tests pass. [Chi tiết](../architecture/mobile-tags.md).
- **Quy đổi hiển thị:** `BE-P2-013` / `MOB-P2-013` done 2026-10-30: tỷ giá người dùng nhập (`UserFxRate`), tiền tệ hiển thị lưu trên tài khoản, Tổng quan cộng tài sản/nợ/ròng/thu/chi đã quy đổi, chi tiết ví và giao dịch hiện số quy đổi kèm tỷ giá. Chỉ hiển thị; báo cáo kỳ vẫn tách từng loại tiền. [ADR 006](../architecture/adr/006-money-and-fx.md).
- **Hóa đơn gộp định kỳ:** `BE-P3-001` done 2026-11-02 (BE): rule `remind` thay `Bill`, xác nhận đã trả idempotent, `/bills` đã bỏ, bảng `Bill` đã xóa (migration `drop_bill_table`). `MOB-P3-001` done 2026-11-04: màn `/me/recurring` thay hai màn cũ. [Chi tiết](../architecture/bills.md).
- **Cho mượn / đi mượn:** `BE-P3-007` done 2026-11-02 (BE): `/personal-debts`, giao dịch `debt` một chân ngoài thu/chi, phải thu/phải trả vào tài sản ròng, nhắc `debt`. `MOB-P3-007` done 2026-11-04. [Chi tiết](../architecture/personal-debts.md).
- **Nhắc ghi chi:** `BE-P3-006` done 2026-11-02 (BE): loại `daily_log`, giờ nhắc theo múi giờ hồ sơ, bỏ qua nếu hôm đó đã có giao dịch. `MOB-P3-006` done 2026-11-04. [Chi tiết](../architecture/notifications.md).
- **Nhập CSV:** `BE-P3-011` done 2026-11-03 (BE): preview/commit/undo, preset Freeva/Money Lover/MISA, trùng bị bỏ qua, hoàn tác cả lô; chỉ CSV, tối đa 2 000 dòng. `MOB-P3-011` done 2026-11-05: màn Nhập giao dịch (nguồn → chọn cột → ghép ví/danh mục → xem trước → xong, hoàn tác cả lô). [Mobile](../architecture/mobile-transaction-import.md). [Chi tiết](../architecture/transaction-import.md).
- **Onboarding ba câu:** `BE-P3-012` done 2026-11-03 (BE): `monthlyIncomeMinor` trên hồ sơ (`PUT /profile/monthly-income`), `PATCH /profile/onboarding` chỉ còn `goals` + thu nhập; bỏ thói quen, nhịp xem lại, ngân sách nhập tay (migration gộp goals cũ). Thu nhập có trong export, xóa cùng tài khoản. `MOB-P3-012` done 2026-11-05: ba câu theo board A3, gợi ý ngân sách, mời bật nhắc ghi chi, thu nhập ở Cá nhân; `POST /goals/preview` cho số cần để dành mỗi tháng; mục tiêu tạo khi đã có ví. [Mobile](../architecture/mobile-onboarding-three-questions.md).
- **Mục tiêu (mobile):** `MOB-P3-E01` done 2026-11-04: `/me/goals` đủ 5 màn theo nhóm I, khối Mục tiêu trên Tổng quan (chọn "Tiết kiệm"), `GET /goals/{id}/entries`, `Profile.monthlyIncomeMinor`. Analyze và test pass. [Chi tiết](../architecture/mobile-goals.md).
- **Ngưỡng ngân sách (mobile):** `MOB-P3-003` done 2026-11-04: mặc định `80, 100`, sheet chip "Báo khi đã dùng" (tối đa 4 mốc), ngân sách cũ giữ mốc. Analyze và 609 test pass.
- **Ẩn quy đổi một loại tiền:** `MOB-P3-004` done 2026-11-04: Tổng quan, chi tiết ví và giao dịch chỉ hiện tổng quy đổi, "Xem tổng theo" và dòng ≈ khi user dùng từ hai loại tiền; tỷ giá đã nhập giữ nguyên. Analyze và 615 test pass.
- **Dự báo số dư:** `BE-P3-E04` done 2026-11-03 (BE): `GET /forecast` theo quy tắc (ví + định kỳ/hóa đơn), nêu giả định, sửa số dư gốc và bỏ khoản; không FX, không dự đoán chi ngoài định kỳ. `MOB-P3-E04` done 2026-11-05: màn `/reports/forecast` từ Báo cáo tháng (3/6/12 tháng, cột số dư, sửa số dư gốc, bật/tắt từng khoản định kỳ). Analyze và 802 test pass. [Mobile](../architecture/mobile-forecast.md). [Chi tiết](../architecture/forecast.md).
- **Xuất CSV:** `BE-P3-010` done 2026-11-03 (BE): `GET /transactions/export.csv`, UTF-8 BOM + RFC 4180, chặn công thức, số tiền thập phân kèm cột tiền tệ, tối đa 50 000 dòng, audit `user.transactions_export`. Không migration. `MOB-P3-010` done 2026-11-05: màn Xuất dữ liệu (CSV lọc thời gian/ví hoặc JSON đầy đủ), chia sẻ qua share sheet. [Mobile](../architecture/mobile-data-export.md). [Chi tiết](../architecture/transactions-csv-export.md).
- **Trả góp thẻ:** `BE-P3-009` done 2026-11-03 (BE): `/card-installments`, lịch trả góp trên khoản chi của ví thẻ (không ghi tiền, khoản mua vẫn tính một lần), `due` cho "số phải trả kỳ này", đóng lịch khi trả trước/hủy. `MOB-P3-009` done 2026-11-05: chuyển khoản chi trên thẻ thành trả góp (xem trước từ `POST /card-installments/preview`), lịch và kết thúc sớm, "Phải trả kỳ này" trên chi tiết thẻ cộng phần trả góp. [Mobile](../architecture/mobile-card-installments.md). [Chi tiết](../architecture/card-installments.md).
- **Hoàn tiền:** `BE-P3-008` done 2026-11-03 (BE): `POST /transactions/{id}/refunds`, giao dịch `refund` một leg trừ vào chi và ngân sách của kỳ khoản gốc (không phải thu nhập), tổng hoàn ≤ khoản gốc, xóa gốc cần chọn `cascade`/`keep`. `MOB-P3-008` done 2026-11-05: ghi hoàn tiền từ chi tiết khoản chi, "đã hoàn" lấy từ `refundedMinor` của API, popup xoá hỏi xử lý hoàn tiền. [Mobile](../architecture/mobile-refunds.md). [Chi tiết](../architecture/refunds.md).
- **Đối soát ví:** `BE-P3-005` done 2026-11-02 (BE): `POST /financial-accounts/{id}/reconcile`, giao dịch `adjustment` một leg ngoài thu/chi và ngân sách, thẻ theo dư nợ. `MOB-P3-005` done 2026-11-04. [Chi tiết](../architecture/wallet-reconciliation.md).
- **Onboarding/tài khoản (nhóm A):** `DS-P2-004` done 2026-10-29: 16 màn khớp canvas, ngân sách nối `BE-P2-E02`, mục tiêu Nợ đưa khối Thẻ tín dụng lên đầu. `BE-P2-012` done 2026-10-30. Còn tách riêng: deep link email, Google/Apple mobile, xác nhận lại email trong Cá nhân. [Chi tiết](../brand/patterns/A-onboarding-auth.md).
- **Tài sản và đầu tư:** `BE-P4-E01` done 2026-11-06 (BE): `/investments` sáu loại, mua/bán bằng giao dịch `investment` một chân (ngoài thu/chi, ngân sách, tỷ lệ tiết kiệm), giá vốn bình quân gia quyền, lãi/lỗ thực hiện trên từng lần bán, giá nhập tay kèm ngày, tiền gửi lãi đơn, giá trị vào tài sản ròng không trùng ví. Migration additive `investments` (deploy trước API). Mobile `MOB-P4-E01` done 2026-11-07 (5 PR): danh sách, tạo, danh mục/bán/giá, tiền gửi, chi tiết/sửa/xoá lần mua ([mobile](../architecture/mobile-investments.md)). [ADR 014](../architecture/adr/014-investment-ledger.md). [Chi tiết](../architecture/investments.md).
- **Tài sản ròng theo thời gian:** `BE-P4-E02` done 2026-11-06 (BE): `GET /reports/net-worth/history` cho 7d/30d/3m/6m/1y/toàn bộ, tính từ sổ cái (ví + cho mượn/đi mượn + đầu tư), điểm mới nhất bằng `/net-worth`, không migration. `MOB-P4-E02` done 2026-11-06: màn `/me/net-worth` với biểu đồ, chip khoảng, chạm điểm. [Mobile](../architecture/mobile-net-worth.md). [Chi tiết](../architecture/reports.md).
- **API đầu tư theo thiết kế:** `BE-P4-E03` done 2026-11-06: tạo kèm lần mua, lần mua có sẵn, sửa/xoá lần mua, % lãi/lỗ, theo danh mục, giá trị theo thời gian. [Chi tiết](../architecture/investments.md).
- **Cờ và cấu hình server:** `BE-P5-E08` done 2026-11-11 (BE): `GET /api/v1/app-config` (cờ đã tính cho user + cấu hình), API admin sửa cờ/giá trị có version và audit trước/sau, `FeatureGuard`. Registry 6 cờ + 34 khóa mặc định bằng giá trị hiện tại; app chưa đọc (`MOB-P5-E08`, `BE-P5-001`). Migration additive `app_config`. Web admin `WA-P5-001` done: trang `/config` sửa cờ và giá trị có bước xác nhận. Backend `BE-P5-001` done 2026-11-11: API áp dụng giá trị đã sửa, khóa giới hạn chỉ đọc, thông báo ở mọi mốc ngân sách user chọn, giờ nhắc mặc định 21:00, `Currency.symbol`; phần app (`MOB-P5-001`) PR 1/3 xong (lựa chọn và ngưỡng), còn tài khoản/nhập liệu/danh mục và tiền tệ. App `MOB-P5-E08` done: đọc cờ và cấu hình từ server, lưu bản trên máy, tải lại khi mở khóa/quay lại app ([mobile](../architecture/mobile-app-config.md)). [Chi tiết](../architecture/app-config.md).
- **Mobile analytics:** `MOB-P0-004` done; catalog typed, debug logger local, `schema_version: 1`, không property tùy ý/PII và chưa có vendor SDK.
- **Backup/restore:** `BE-P0-005` done; [runbook và bằng chứng local](../../infra/runbooks/backup-restore.md), PostgreSQL 16.14. Production PITR/retention/RPO/RTO chưa triển khai.
- **Scaffold:** xong trên `main` (`153d3e7`). Health API, admin placeholder, Flutter shell, docs, compose.
- **Auth API:** `BE-P1-001` / `BE-P1-002` done; `BE-P1-003` Google/Apple ID token backend done — mobile mới có nút giữ chỗ (báo “sắp có”), chưa SDK, chưa live provider smoke.
- **Financial accounts:** `BE-P1-004` done: CRUD bốn loại ví, số dư derived bigint, credit config, sắp xếp/lưu trữ/khôi phục, owner/version/clientId; 117 unit và 33 PostgreSQL integration tests, build/OpenAPI pass. Không migration mới. [Thiết kế](../architecture/financial-accounts.md).
- **Transactions:** `BE-P1-005` done: CRUD thu/chi/transfer nguyên tử, FX exact/quote bất biến, soft-delete/restore cả cặp, owner/version/Idempotency-Key/clientId, category/tags/filter. 145 unit/HTTP + 51 PostgreSQL tests, build/OpenAPI pass; không migration. [Thiết kế](../architecture/transactions.md).
- **Categories:** `BE-P1-006` / `BE-P1-011` done: bộ VN, custom, `kind`, supplement một lần. Migration additive cần deploy trước API. [Thiết kế](../architecture/categories.md).
- **Reports / search:** `BE-P1-007` / `BE-P1-008` / `BE-P2-E06` / `BE-P2-E08` done (cashflow so kỳ + savings rate + top merchant; `GET /reports/series`; `GET /reports/month-review`).
- **Tags / merchant:** `BE-P1-012` done. Migration `transaction_merchant`. [Thiết kế](../architecture/tags.md).
- **Sync queue:** `BE-P1-009` done: `POST /api/v1/sync` áp hàng đợi giao dịch, idempotent theo `clientId`, conflict không ghi đè, gợi ý trùng 10 phút. 19 unit suites / 179 tests và 6 PostgreSQL suites / 75 tests, build/OpenAPI pass. Một migration seed `SchemaMeta`. [Thiết kế](../architecture/sync.md).
- **Export / xóa tài khoản:** `BE-P1-010` done: `GET /api/v1/account/export` và `DELETE /api/v1/account`, audit fail closed, UUID audit được giữ. 20 unit suites / 185 tests và 7 PostgreSQL suites / 79 tests, build/OpenAPI pass. Không migration. [Thiết kế](../architecture/account-privacy.md).
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

## Backlog Phase 2

- **21/21 done.** Chi tiết: [tasks/phase-02.md](../../tasks/phase-02.md).

## Phase 0 gate — đã đóng (2026-09-21)

Theo [điều kiện hoàn thành Phase 0](../product/phases/phase-00.md) và [DECISIONS-OPEN](DECISIONS-OPEN.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P0 | Done (25/25) |
| Data model + security flow review | Done (ADR 007/008, threat model, PII checklist) |
| Backup/restore thử | Done local (`BE-P0-005`); production PITR chưa |
| Staging cloud | Done — `INF-P0-004`; URL ở mục Staging trên |
| Crash monitoring | SDK done (`INF-P1-001`) |
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
| Onboarding → ví → giao dịch đầu | Done code + unit/widget (`MOB-P1-001`…`004`) |
| Số dư đúng sau thu/chi/chuyển/sửa/xóa | Done (`BE-P1-004`, `BE-P1-005`, `MOB-P1-003`, `MOB-P1-004`) |
| Sync không tạo trùng (kịch bản chính) | Done (`BE-P1-009`, `MOB-P1-008`) |
| Báo cáo khớp nguồn | Done (`BE-P1-007`, `MOB-P1-006`); không cộng khác loại tiền |
| Export, xóa TK, reset password, thu hồi phiên | Done (`BE-P1-010`, `BE-P1-001`/`002`, `MOB-P1-001`) |
| Security checklist trước store (skeleton) | Done (`SEC-P1-001`); residual ghi rõ |
| Crash monitoring SDK | Done (`INF-P1-001`); DSN live chờ vận hành |

Đóng theo option **B** (giống Phase 0): backlog + gate sổ cái xong trên `main` → mở Phase 2.

## Phase 2 gate — đã đóng (2026-10-30)

Theo [điều kiện hoàn thành Phase 2](../product/phases/phase-02.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P2 | Done 21/21 |
| Đã chi / còn lại theo ngân sách | Done (`BE-P2-E02` / `MOB-P2-E02`, `Gate: v1`) |
| Không trùng giao dịch định kỳ khi sync/retry | Done (`BE-P2-E01`, `QA-P2-001`) |
| Nhắc đúng TZ, giờ yên lặng, consent | Done (`BE-P2-E05`, `BE-P2-015` FCM) |
| Hóa đơn đã trả truy vết được giao dịch | Done (`BE-P2-E03` / `MOB-P2-E03`) |

Đóng theo option **B** (giống Phase 0, 1): backlog xong trên `develop` → mở Phase 3.

## Backlog Phase 3

- **16/17 done**, `BE-P3-E03` wont (gộp vào `BE-P4-E01`). Chi tiết: [tasks/phase-03.md](../../tasks/phase-03.md).

## Backlog Phase 4

- **6/6 done**: `BE-P4-E01`, `BE-P4-E02`, `DS-P4-001`, `BE-P4-E03`, `MOB-P4-E02`, `QA-P4-E01` (kèm `MOB-P4-E01` 2026-11-07; FX không hỗ trợ ở v1, chốt 2026-11-09). Chi tiết: [tasks/phase-04.md](../../tasks/phase-04.md).

## Backlog Phase 5

- **3/10 done** (`BE-P5-E08`, `WA-P5-001`, `MOB-P5-E08`), 3 wont (`BE-P5-E01` bỏ; `E02`, `E05` sang Phase 8). Chi tiết: [tasks/phase-05.md](../../tasks/phase-05.md).

## Phase 3 gate — đã đóng (2026-11-05)

Theo [điều kiện hoàn thành Phase 3](../product/phases/phase-03.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P3 | Done 16/17; `BE-P3-E03` wont |
| Lãi, dư nợ, dự báo có bộ test ví dụ chuẩn | Done (`BE-P3-E02` 100tr · 12% → lãi kỳ 1 = 1tr; `BE-P3-E01` 120tr − 40tr / 10 tháng = 8tr; `BE-P3-E04` số cố định) |
| Tiền ở mục tiêu/vay có giao dịch đối ứng hoặc audit | Done (`goal.adjust`, `loan.adjust`, transfer hai chân) |
| User thấy giả định và sửa được input | Done (`BE-P3-E04` / `MOB-P3-E04`) |
| Mục tiêu `Gate: v1` | Done (`BE-P3-E01` / `MOB-P3-E01`) |

Đóng theo option **B** (giống Phase 0, 1, 2): backlog xong trên `develop` → mở Phase 4.

## Phase 4 gate — đã đóng (2026-11-10)

Theo [điều kiện hoàn thành Phase 4](../product/phases/phase-04.md):

| Mục | Trạng thái |
|---|---|
| Backlog task P4 | Done 6/6 (`BE-P4-E01`/`MOB-P4-E01`, `BE-P4-E02`, `DS-P4-001`, `BE-P4-E03`, `MOB-P4-E02`, `QA-P4-E01`) |
| Không tính trùng ví / tài sản / đầu tư | Done (`BE-P4-E02`: chuỗi 6 tháng thu/chi/chuyển khoản/vàng/cho mượn, 95 → 112 → 117 → 122 triệu; vị thế đầu tư không cộng trùng ví) |
| Công thức giá vốn, lãi/lỗ có tài liệu + test | Done ([ADR 014](../architecture/adr/014-investment-ledger.md), `investment.spec.ts` 29 test, `investments.integration-spec.ts` PostgreSQL; vàng chỉ/lượng, crypto 8 chữ số, lãi tiền gửi, mua → góp → bán). FX: v1 không hỗ trợ (chốt 2026-11-09) |
| Nguồn giá và độ trễ luôn hiện | Done (giá nhập tay kèm ngày báo giá trên thẻ tài sản; khoản chưa có giá hiện "Chưa có giá") |
| Mục `Gate: v1` | Done (tài sản và đầu tư, tài sản ròng theo thời gian, test giá vốn) |

Đóng theo option **B** (giống Phase 0–3): backlog xong trên `develop` → mở Phase 5. Chưa làm: chạy thử trọn luồng đầu tư trên simulator/thiết bị với backend thật; footer "Đã bán hết" và màn xem lại từng lần bán (ngoài thiết kế đã chốt).

## Ghi chú

Local: API `:4000`, Postgres compose `:5434`, admin `:3001`.
