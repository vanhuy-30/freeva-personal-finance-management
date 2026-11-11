# Changelog dự án

Nhật ký repo/process — không phải App Store release notes.

## 2026-11-11

- `MOB-P5-001` PR 2/3: app tải cấu hình công khai trước đăng nhập; quy tắc mật khẩu, số lần sai PIN, độ dài tên/ghi chú, nhãn, ngày đầu kỳ, onboarding, nhập/xuất CSV, góp ý lấy từ server; tên hiển thị tối đa 60; dòng thông báo mục tiêu/soát tháng theo server; phiên bản app đọc từ gói cài đặt.
- `BE-P5-001` bổ sung: `GET /api/v1/app-config/public` — số cấu hình không cần đăng nhập (không cờ, không dữ liệu user) cho màn đăng ký/đặt lại mật khẩu.
- `MOB-P5-001` PR 1/3: app chỉ chạy phần đã đăng nhập khi có cấu hình server (lỗi thì một màn Thử lại); mốc ngân sách, dự báo, trả góp, nhắc trước, mức dùng thẻ, sắp đến hạn, khoảng biểu đồ, top báo cáo, giao dịch gần đây, ngày mục tiêu, bước phút, giờ nhắc lấy từ cấu hình. Màn Thông báo: "Khi chạm mốc bạn chọn".
- `BE-P5-001` (backend): API dùng giá trị staff sửa thay hằng số (mốc ngân sách, dự báo, định kỳ, mức dùng thẻ, giờ nhắc, nhập/xuất CSV, số nhãn, tên hiển thị, mục tiêu onboarding, mật khẩu tối thiểu); 24 khóa giới hạn chỉ đọc cho app; kiểm tra chéo khi lưu; thông báo ngân sách ở mọi mốc user chọn (bỏ sàn 80%); giờ nhắc ghi chi mặc định 21:00; ký hiệu tiền tệ trong `/profile/options`. Migration `config_enforce`. Mobile còn 3 PR.
- `MOB-P5-E08` (mobile): app đọc cờ và cấu hình từ `GET /app-config` — bản lưu trên máy dùng ngay lúc mở app, tải lại khi mở khóa và khi quay lại app (tối đa mỗi giờ), xóa khi đăng xuất; chưa tải được thì cờ tắt và khối cần số hiện "Thử lại". Cờ dev bật qua `FEATURE_FLAGS_ON` chỉ ở bản dev. [Thiết kế](../architecture/mobile-app-config.md).
- `WA-P5-001` (web admin): trang Cờ và cấu hình `/config` — nhập credential staff, xem cờ và khóa theo nhóm (mô tả, mặc định, giới hạn, lần sửa cuối), sửa có bước xác nhận trước/sau, về mặc định, lỗi hiện tại ô nhập, báo khi người khác vừa sửa. Header admin thêm điều hướng.
- `BE-P5-E08` (backend): cờ và cấu hình phía server — `GET /api/v1/app-config`, API admin sửa cờ (bật/tắt, danh sách user, phần trăm) và giá trị cấu hình có version chống ghi đè, mỗi lần sửa lưu trước/sau và audit trong một transaction, `FeatureGuard` trả `403 FEATURE_DISABLED`. 6 cờ, 34 khóa mặc định bằng giá trị app đang dùng. Migration additive `app_config`. [Thiết kế](../architecture/app-config.md).
- Chốt phạm vi Phase 5: số và cấu hình sản phẩm lên server, sửa trên web admin (`BE-P5-E08`, `WA-P5-001`, `MOB-P5-E08`, `BE-P5-001`/`MOB-P5-001` kèm danh sách rà soát app); gợi ý danh mục, insight, dự báo chi, what-if theo quy tắc. `BE-P5-E01` (sao kê) wont. OCR, Ask Freeva sang Phase 8 mới (AI). Bỏ cờ `investment`; cờ ngân hàng Phase 6 đổi tên `bank_connect`.

## 2026-11-10

- **Phase 4 closed**: backlog 6/6 done (tài sản và đầu tư, tài sản ròng theo thời gian, thiết kế, test giá vốn; `Gate: v1`). FX đầu tư không hỗ trợ ở v1. Mở Phase 5 (toàn bộ sau v1).

## 2026-11-09

- `QA-P4-E01` done: chủ dự án chốt v1 không hỗ trợ vị thế khác tiền tệ ví (không tỷ giá trong đầu tư). Phase 4 đủ 6/6 task. Mở lại khi cần: ADR và task riêng.

## 2026-11-07

- `MOB-P4-E01` PR 5/5 (xong task): chi tiết lần mua, sửa lần mua (phát lại vị thế, chân ví theo), xoá lần mua có xác nhận và nêu tiền trả lại ví; `pairs.py` nhóm `P`. Đầu tư trên app đủ P.1–P.12. [Thiết kế](../architecture/mobile-investments.md).
- `MOB-P4-E01` PR 4/5: tiền gửi trên app — chi tiết (giá trị hôm nay, gốc, lãi tạm tính, lãi suất, đáo hạn còn bao nhiêu ngày), rút tiền gửi, sửa khoản, xoá khoản. [Thiết kế](../architecture/mobile-investments.md).
- `MOB-P4-E01` PR 3/5: màn danh mục đầu tư (P.3) với từng tài sản, giá, các lần mua và dòng đã bán; bán một phần hoặc hết có xem trước lãi chốt (P.9); cập nhật giá nhập tay (P.10); Mua thêm. [Thiết kế](../architecture/mobile-investments.md).
- `MOB-P4-E01` PR 2/4: tạo khoản đầu tư trên app — màn `/me/investments/new` (sáu danh mục, vàng chỉ/lượng, tiền gửi lãi suất và đáo hạn, bất động sản một lô), số lượng Decimal 8 chữ số bằng `BigInt`, lấy từ ví hoặc "đã có từ trước". Nút thêm ở P.1 và P.2. [Thiết kế](../architecture/mobile-investments.md).
- `MOB-P4-E01` PR 1/4: nền đầu tư trên app — `TransactionType.investment` (một chân, khoá sửa/xoá), màn `/me/investments` (thẻ tổng, tỷ trọng, danh mục, tag chưa có giá), ô "Đầu tư" ở lưới Cá nhân, dòng Đầu tư ở Tài sản ròng mở màn này. Chưa thêm được khoản đầu tư (PR 2). [Thiết kế](../architecture/mobile-investments.md).

## 2026-11-06

- `MOB-P4-E02`: biểu đồ tài sản ròng trên app — màn `/me/net-worth` (số hôm nay, thay đổi theo khoảng, đường, chip 7 ngày → Tất cả, chạm điểm xem ngày và số, Tài sản · Nợ, Ví · Đầu tư), ô "Tài sản ròng" ở lưới Cá nhân. Không đổi backend. Golden sáng/tối, đối chiếu board nhóm Q. [Thiết kế](../architecture/mobile-net-worth.md).

- `BE-P4-E03` (backend): API đầu tư theo thiết kế P — tạo tài sản kèm lần mua đầu (gộp khi trùng tên), lần mua "đã có từ trước" không trừ ví, giá một đơn vị trên trade (giá mua/bán thành giá hiện tại), sửa/xoá từng lần mua kéo theo chân ví và phát lại vị thế, `%` lãi/lỗ, tổng hợp và tỷ trọng theo danh mục, `GET /reports/investments/history`. Migration additive `investment_trade_edit`. 12 unit + 10 integration test mới. [Thiết kế](../architecture/investments.md).

- `BE-P4-E02` (backend): `GET /reports/net-worth/history` — tài sản ròng cuối mỗi mốc của cửa sổ 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm, toàn bộ; tính lại từ sổ cái (ví, cho mượn/đi mượn, vị thế đầu tư phát lại tới từng ngày), không trùng ví/đầu tư, điểm mới nhất bằng `/net-worth`. Không migration. 17 unit + 8 integration test mới. [Thiết kế](../architecture/reports.md).

- `BE-P4-E01` (backend): tài sản và đầu tư — ADR 014 (ghi sổ), `/api/v1/investments` (vàng chỉ/lượng, cổ phiếu, chứng chỉ quỹ, tiền gửi, bất động sản, crypto), mua/bán bằng giao dịch `investment` một chân, giá vốn bình quân gia quyền, lãi/lỗ thực hiện, giá nhập tay, tiền gửi lãi đơn, giá trị vào `/reports/net-worth`, `byAccount.investmentMinor`, export/xoá tài khoản. Migration `investments` additive. Unit 29 + integration 11 test mới; 24 suite integration PostgreSQL xanh. Mobile chưa làm. [Thiết kế](../architecture/investments.md).

## 2026-11-05

- **Phase 3 closed**: backlog 16/17 done, `BE-P3-E03` wont (gộp vào `BE-P4-E01`); gồm mục tiêu, vay và nợ, dự báo số dư, ticket `P3-001`…`012` (`Gate: v1`). Mở Phase 4.
- Dọn backlog: xóa bảng `Bill` cũ (migration `drop_bill_table`), module `/bills` 410 và trường `bills` trong export tài khoản; xóa các tồn đọng bị chặn vì chưa có tài khoản store/server deploy, đã lỗi thời hoặc không cần; căn lại 6 foreign key tùy chọn về `ON DELETE SET NULL` đúng schema (migration `align_optional_fk_actions`); 23 suite integration PostgreSQL chạy xanh trên Postgres local.
- `MOB-P3-E04`: dự báo số dư trên app — dòng "Dự báo số dư" ở Báo cáo tháng mở màn công tắc 3/6/12 tháng, thẻ số dư cuối kỳ và chênh so với hôm nay, cột số dư từng tháng, thẻ Cách tính (sửa số dư gốc), danh sách khoản định kỳ/hóa đơn có công tắc bật/tắt. Không đổi backend. Golden sáng/tối, đối chiếu board nhóm N. [Thiết kế](../architecture/mobile-forecast.md).
- `MOB-P3-011`: nhập CSV từ app khác trên app — dòng "Nhập từ app khác" ở Hồ sơ mở màn Nhập giao dịch: chọn nguồn (Money Lover, MISA, Freeva, Nơi khác), chọn file CSV, chọn cột cho file Nơi khác, ghép ví và danh mục chưa khớp, xem trước Sẵn sàng/Trùng/Lỗi, nhập một lô và hoàn tác cả lô. Thêm dependency `file_picker`. Không đổi backend. [Thiết kế](../architecture/mobile-transaction-import.md).
- `MOB-P3-012` (+ `BE-P3-012` bổ sung): onboarding ba câu trên app — mục tiêu sử dụng (tối đa 2), thu nhập tháng, mục tiêu tiết kiệm; màn gợi ý ngân sách khi có thu nhập; sheet mời bật nhắc ghi chi trên Tổng quan sau giao dịch đầu; dòng "Thu nhập hàng tháng" ở Cá nhân. Hết lỗi 400 ở onboarding. API thêm `POST /goals/preview` (không migration). Mục tiêu tiết kiệm tạo khi đã có ví. Token `data.saving`. Golden sáng/tối, đối chiếu board A3. [Thiết kế](../architecture/mobile-onboarding-three-questions.md).
- `MOB-P3-009` (+ `BE-P3-009` bổ sung): trả góp thẻ trên app — hàng "Chuyển thành trả góp" trong chi tiết khoản chi trên thẻ, màn tạo lịch (số kỳ, mỗi kỳ, kỳ đầu; mọi số từ API preview), lịch trả góp và kết thúc sớm, "Phải trả kỳ này" + nhóm TRẢ GÓP trên chi tiết thẻ. Kết thúc rồi tạo lại để sửa kế hoạch sai; khoản chi đang trả góp có hàng "Xem lịch trả góp". API thêm `POST /card-installments/preview`, tên khoản mua trên kế hoạch, `installmentPlanId` trên khoản chi, tạo mới thay kế hoạch đã kết thúc (không migration). Golden sáng/tối + 1.3×, đối chiếu board nhóm M. [Thiết kế](../architecture/mobile-card-installments.md).
- `MOB-P3-008` (+ `BE-P3-008` bổ sung): hoàn tiền trên app — card "Ghi hoàn tiền" trong chi tiết khoản chi, sheet ghi hoàn tiền (chip hoàn toàn bộ phần còn lại, ví cùng tiền tệ, ngày), popup xoá khoản chi có hoàn tiền (`cascade` / `keep`), dòng và chi tiết giao dịch `refund`, "đã hoàn" dưới khoản chi. API thêm `refundedMinor` trên khoản chi ở `GET /transactions` và `GET /transactions/{id}` (không migration). Golden sáng/tối + 1.3×, đối chiếu board nhóm M. [Thiết kế](../architecture/mobile-refunds.md).

## 2026-11-04

- `MOB-P3-002`: thẻ soát tháng trên Tổng quan thêm hai dòng: danh mục chi tăng nhiều nhất so với tháng trước nữa và ngân sách tháng trước có vượt không (số lấy từ `reports/cashflow` và `budgets/current`, không AI, thiếu dữ liệu thì bỏ dòng). Không đổi backend. Golden sáng/tối.
- `MOB-P3-001`: màn "Định kỳ và hóa đơn" trên app — một màn cho khoản ghi tự động và hóa đơn hỏi trước khi ghi, "Đã trả" (`POST /recurring-transactions/{id}/confirm`), thêm/sửa theo board nhóm L. Bỏ màn Hóa đơn và `/me/bills` (API đã trả 410), bỏ dòng Hóa đơn ở Cá nhân. Không đổi backend. Golden sáng/tối + 1.3×. [Thiết kế](../architecture/mobile-recurring-bills.md).
- `MOB-P3-E01`: màn Mục tiêu trên app (danh sách, trống, tạo/sửa, chi tiết, góp/rút), khối Mục tiêu trên Tổng quan, ô Mục tiêu ở Cá nhân đếm thật. Thêm `GET /api/v1/goals/{id}/entries` (lịch sử; không migration) và `monthlyIncomeMinor` trong `Profile` mobile. Golden sáng/tối. [Thiết kế](../architecture/mobile-goals.md).

## 2026-11-03

- `BE-P3-012`: onboarding ba câu — `User.monthlyIncomeMinor`, `PATCH /api/v1/profile/onboarding` chỉ nhận `goals` (`track|save|budget`) và `monthlyIncomeMinor`, `PUT /api/v1/profile/monthly-income` đặt/sửa/xóa; migration bỏ `trackingHabit`, `reviewCadence`, `onboardingBudgetMinor` và gộp goals cũ. Export cập nhật. `MOB-P3-012` chưa làm nên màn onboarding hiện tại nhận 400 tới khi làm.
- `BE-P3-E04`: dự báo số dư theo quy tắc — `GET /api/v1/forecast` (số dư ví không phải thẻ cộng định kỳ và hóa đơn thu/chi theo tháng, `assumptions` nêu giả định, sửa được số dư gốc và bỏ khoản, cùng một loại tiền, không gọi model). Không migration. `MOB-P3-E04` chưa làm. [Thiết kế](../architecture/forecast.md).
- `BE-P3-011`: nhập CSV từ app khác — `POST /api/v1/transactions/import/preview` (không ghi), `POST /api/v1/transactions/import` (một lô, idempotent theo `batchClientId`), `GET`/`POST …/{id}/undo`. Preset Freeva (khớp xuất `BE-P3-010`), Money Lover, MISA, tùy chỉnh; map ví/danh mục, kết quả từng dòng, trùng thì đánh dấu và bỏ qua, hoàn tác cả lô. Migration `20261103300000_transaction_import_batch` (additive; cần deploy trước API). `MOB-P3-011` chưa làm. [Thiết kế](../architecture/transaction-import.md).
- `BE-P3-010`: xuất CSV giao dịch — `GET /api/v1/transactions/export.csv` (bộ lọc như danh sách, UTF-8 BOM, RFC 4180, chặn `= + - @`, `amount` thập phân không theo locale kèm cột `currency`, tối đa 50 000 dòng, audit `user.transactions_export`). Không migration. `MOB-P3-010` chưa làm. [Thiết kế](../architecture/transactions-csv-export.md).
- `BE-P3-009`: trả góp thẻ tín dụng — `/api/v1/card-installments` (tạo từ một khoản chi trên ví thẻ, chi tiết kèm lịch kỳ, `due` tổng phần trả góp đến hạn theo thẻ, `close` khi trả trước hoặc hủy). Chỉ là lịch: khoản mua vẫn một khoản chi, báo cáo, ngân sách và dư nợ không đổi; xóa khoản chi tự đóng lịch; export/xoá tài khoản. Migration `20261103200000_card_installments` (additive; cần deploy trước API). `MOB-P3-009` chưa làm. [Thiết kế](../architecture/card-installments.md).
- `BE-P3-008`: hoàn tiền gắn khoản chi gốc — `POST /api/v1/transactions/{id}/refunds` tạo giao dịch `refund` một leg (tổng hoàn ≤ khoản gốc, idempotent theo `clientId`), trừ vào chi của danh mục và ngân sách tại kỳ của khoản gốc thay vì tính thu nhập; xóa khoản gốc còn hoàn tiền cần `refunds=cascade|keep`. Migration `20261103100000_transaction_refund` (additive; cần deploy trước API). `MOB-P3-008` chưa làm. [Thiết kế](../architecture/refunds.md).

## 2026-11-02

- `INF-P3-001`: job `mobile` thêm `dart format --output=none --set-exit-if-changed lib test tool` sau `flutter pub get`; format toàn bộ `apps/mobile` một lần (65 file, chỉ đổi format).
- `BE-P3-007`: cho mượn / đi mượn — `/api/v1/personal-debts` (CRUD, `summary` ai nợ mình / mình nợ ai, `payments` trả một phần nhiều lần, tất toán), giao dịch `debt` một chân ngoài thu/chi và ngân sách, phải thu/phải trả vào tài sản ròng, nhắc `debt_due` / `debt_overdue`, export/xoá tài khoản. Migration `20261102500000_personal_debts` (additive, thêm giá trị enum); cần deploy trước API. MOB-P3-007 chưa làm. [Thiết kế](../architecture/personal-debts.md).
- `BE-P3-006`: nhắc ghi chi hằng ngày — loại thông báo `daily_log` (mặc định tắt), `dailyLogEnabled` / `dailyLogTime` (HH:mm, múi giờ hồ sơ) trên `/notification-preferences`; không tạo nếu hôm đó đã có thu/chi/chuyển, tôn trọng giờ yên, một hàng mỗi ngày. Migration `20261102400000_daily_log_reminder` (additive); cần deploy trước API. MOB-P3-006 chưa làm. [Thiết kế](../architecture/notifications.md).
- `BE-P3-005`: đối soát số dư ví — `POST /api/v1/financial-accounts/{id}/reconcile` tạo giao dịch `adjustment` một leg (không phải thu/chi, không vào ngân sách/tỷ lệ tiết kiệm), thẻ tín dụng theo dư nợ. Migration `20261102300000_transaction_adjustment` (additive, thêm giá trị enum); cần deploy trước API. MOB-P3-005 chưa làm. [Thiết kế](../architecture/wallet-reconciliation.md).
- `BE-P3-001`: gộp hóa đơn vào giao dịch định kỳ — rule `remind` thay `Bill`, `POST /recurring-transactions/{id}/confirm`, nhắc `bill_due` / `bill_overdue`, lịch đọc từ rule, `/api/v1/bills` trả 410. Migration `20261102200000_recurring_remind_mode` (additive, giữ bảng `Bill`); cần deploy trước API. MOB-P3-001 chưa làm. [Thiết kế](../architecture/bills.md).
- **Phạm vi product v1 đổi** (quyết định chủ dự án): `BE-P4-E01` / `MOB-P4-E01` và `QA-P4-E01` (tài sản và đầu tư) thành `Gate: v1`; `BE-P5-E03`, `BE-P5-E04`, `BE-P5-E08`, `PRD-P5-E01` (gợi ý danh mục, insight, cờ server, consent AI) thành `post-v1`. Đồng bộ roadmap, MoSCoW, spec-alignment, STATUS, tasks. Roadmap sửa “Phase hiện tại” từ 2 thành 3.
- **Phạm vi v1 bổ sung** (quyết định chủ dự án): `BE-P4-E02` tài sản ròng thành `Gate: v1`; đầu tư v1 gồm vàng, cổ phiếu, quỹ, tiền gửi, bất động sản, crypto, giá nhập tay, mua = chuyển vào giá vốn. Module 11 gộp vào 12 (`BE-P3-E03` wont). Thêm `P3-001`…`011`: gộp hóa đơn vào định kỳ, thẻ soát tháng, ngưỡng ngân sách 80/100, ẩn quy đổi, đối soát số dư, nhắc ghi chi, cho mượn/đi mượn, hoàn tiền, trả góp thẻ, xuất CSV, nhập CSV. Trạng thái task thêm `wont`.
- Chốt thêm: trả góp ghi chi một lần lúc mua (`BE-P3-009`); lãi/lỗ bán đầu tư chỉ hiện ở màn đầu tư; onboarding còn ba câu — mục tiêu sử dụng, thu nhập, mục tiêu tiết kiệm (`DS-P3-012` / `BE-P3-012` / `MOB-P3-012`). `MOB-P3-002` thu hẹp vì thẻ soát tháng đã có.

## 2026-10-30

- **Phase 2 closed**: backlog 21/22 done, gồm `BE-P2-E02` ngân sách (`Gate: v1`). `INF-P2-001` (Postgres staging) chuyển phase sau theo quyết định chủ dự án; develop dùng Postgres local. Residual ghi ở [STATUS](STATUS.md).

## 2026-10-21

- **Phase 1 closed** (option B): backlog 28/28 done; điều kiện sổ cái đạt trên `main`; residual deploy staging, E2E native/Resend, DSN Sentry và nút OAuth mobile ghi rõ. Mở Phase 2 (ngân sách / định kỳ / …). Biên bản: [STATUS](STATUS.md), [phase-01](../product/phases/phase-01.md).

## 2026-10-20

- `BE-P1-012`: CRUD `/api/v1/tags` theo owner (replay `clientId`, xóa gỡ link và tăng version giao dịch); `merchant` optional trên thu/chi, cấm trên transfer; export/sync kế thừa DTO; redact `merchant` trong log. 23 unit suites / 209 tests và 9 HTTP/PostgreSQL suites / 87 tests, build/OpenAPI pass. Migration additive `20261020120000_transaction_merchant`; chưa deploy staging. [Thiết kế](../architecture/tags.md).

## 2026-10-19

- `MOB-P1-001`: đóng task. Face ID, vân tay và màn hình recents đã test pass trên thiết bị thực. E2E gửi email Resend trên staging hoãn có chủ đích đến khi setup Resend; chưa kiểm chứng delivery/inbox. [Runbook](../infrastructure/email.md).

## 2026-10-12

- `INF-P1-001`: gắn Sentry cho crash staging trên API, web admin và mobile. SDK tắt khi không có DSN; scrub PII trước khi gửi; không endpoint public và không tracing. 22 unit suites / 192 tests và API build pass; admin tsc, lint và 2 node tests pass; Flutter analyze sạch và 133 tests pass (3 mới). Event trên dashboard chờ DSN vận hành. [ADR 011](../architecture/adr/011-sentry-crash-monitoring.md).

- `MOB-P1-009`: giữ màn che khi app vào nền; nút mắt và công tắc Cài đặt che số đang đọc, ô đang gõ vẫn hiện. Sau mở khóa, phiên khác chưa từng thấy thì banner và thông báo cục bộ một lần. Xin quyền đúng lúc cảnh báo đầu. Đăng xuất xóa danh sách phiên đã thấy; khóa PIN không xóa. Không đổi API, không gọi là thiết bị mới. Analyze sạch và 130 Flutter tests pass (13 tests mới); chưa native build/E2E staging. [Thiết kế](../architecture/mobile-privacy.md).

- `BE-P1-010`: `GET /api/v1/account/export` trả snapshot JSON của owner; `DELETE /api/v1/account` xóa ngay user và dữ liệu tài chính. Audit `user.data_export` / `user.account_delete` cùng transaction, fail closed, UUID còn sau khi user biến mất. Không CSV, không UI, không cửa sổ 30 ngày trên ứng dụng. 20 unit suites / 185 tests và 7 HTTP/PostgreSQL suites / 79 tests, build/OpenAPI pass. Không migration; chưa deploy staging. [Thiết kế](../architecture/account-privacy.md).

## 2026-10-09

- `MOB-P1-008`: hàng đợi mutation giao dịch khi mất mạng, lưu trong secure storage, gửi lại bằng `POST /api/v1/sync`. Gộp sửa/xóa trước khi gửi, conflict không ghi đè, `review` khi số tiền khác. Không sync ví/danh mục và không cộng số dư từ bản chờ. Analyze sạch và 117 Flutter tests pass (9 tests mới); chưa native build/E2E staging. [Thiết kế](../architecture/mobile-sync.md).

- `BE-P1-009`: `POST /api/v1/sync` áp tuần tự create/update/delete giao dịch. Replay theo `clientId` không tạo thêm dòng; conflict giữ bản server và chỉ bật `review` khi số tiền khác. Gợi ý trùng trong 10 phút không chặn tạo. `schemaVersion` phải khớp `SchemaMeta`. CRUD giao dịch hiện có không đổi. 19 unit suites / 179 tests và 6 HTTP/PostgreSQL suites / 75 tests, build/OpenAPI pass. Một migration seed `SchemaMeta`; chưa deploy staging. [Thiết kế](../architecture/sync.md).

- `MOB-P1-007`: cài đặt theme trên thiết bị, lối sang hồ sơ cho ngôn ngữ/tiền tệ/múi giờ, bật/tắt sinh trắc, onboarding một lần với `onboarding_started`/`onboarding_completed`, FAQ, phản hồi chỉ sao chép cục bộ, phiên bản và bản nháp ToS/privacy. Không đổi API và không gửi nội dung phản hồi. Analyze sạch và 108 Flutter tests pass (14 tests mới); chưa native build/E2E staging. [Thiết kế](../architecture/mobile-settings.md).

- `MOB-P1-006`: tổng quan trên Home và màn báo cáo lọc tuần, tháng, khoảng ngày. Tài sản/nợ/ròng hiện tại và thu/chi/dòng tiền theo từng loại tiền; danh mục lá giữ tên cha, thu chưa phân loại có nhãn. Không cộng khác loại tiền, không đổi API. `report_viewed` một lần mỗi lượt mở báo cáo. Analyze sạch và 94 Flutter tests pass (14 tests mới); chưa native build/E2E staging. [Thiết kế](../architecture/mobile-reports.md).

## 2026-10-08

- Đối chiếu spec sản phẩm v0.1: Phase 1 giữ vai trò sổ cái; product v1 thêm ngân sách, mục tiêu và insight cơ bản. Bản spec nằm ở [freeva-product-spec.md](../product/freeva-product-spec.md); quyết định lệch ở [spec-alignment.md](../product/spec-alignment.md). Task còn mở và epic Phase 2–7 có DoD kiểm được.

- `MOB-P1-005`: UI danh mục từ Home, cây cha-con, tạo/sửa custom, màu và icon theo catalog, ẩn/khôi phục và xóa vĩnh viễn kèm danh mục thay thế. Abstract DI, version/clientId, chặn ghi sau conflict, xóa state khi khóa. Analyze sạch và 80 Flutter tests pass (10 tests mới); chưa native build/E2E staging. [Thiết kế](../architecture/mobile-categories.md).

## 2026-09-25

- `BE-P1-005`: CRUD transactions thu/chi/transfer hai leg nguyên tử; BigInt và manual FX exact, quote bất biến; owner/session, Idempotency-Key/clientId, optimistic version, danh mục chi bắt buộc, nhãn/ghi chú, lọc/phân trang và soft-delete/restore cả cặp. Writer phối hợp khóa/update hàng ví để chống race đổi denomination từ snapshot cũ. 145 unit/HTTP + 51 PostgreSQL integration tests, build/OpenAPI pass; không migration mới, chưa deploy staging. [Thiết kế](../architecture/transactions.md).

- `MOB-P1-003`: UI ví từ Home, danh sách/tạo/sửa bốn loại ví, cấu hình thẻ, sắp xếp lên/xuống và ẩn/khôi phục qua API hiện có. BigInt và formatter vi/en theo minorDigits, abstract DI, version/clientId, chặn mutation sau lỗi reorder một phần, xóa state/bản nháp khi khóa. Analyze và 11 tests mới pass; chưa native build/E2E staging. [Thiết kế](../architecture/mobile-wallets.md).

## 2026-09-24

- `BE-P1-004`: CRUD financial accounts theo Bearer session owner; tiền string/bigint, số dư derived cùng snapshot; cấu hình thẻ, sortOrder, archive/restore; optimistic version và clientId chống trùng. Khóa loại/tiền tệ sau khi có giao dịch, cho đính chính số dư ban đầu. OpenAPI, tài liệu và regression tests cập nhật; 117 unit và 33 PostgreSQL integration tests, build/OpenAPI pass. Không migration mới; chưa deploy staging. [Thiết kế](../architecture/financial-accounts.md).

## 2026-09-23

- `MOB-P1-002`: màn hồ sơ locale/currency/TZ/kỳ tài chính, API và OpenAPI theo session owner, optimistic version chống ghi đè; locale áp dụng sau lưu, bản nháp/lỗi/retry và privacy gate. Unit/widget/HTTP/PostgreSQL tests, analyze và API build pass. Backend cần deploy trước mobile; chưa E2E staging/native. [Thiết kế](../architecture/mobile-profile.md).

- `DOC-P1-001`: thêm trang current-state tập trung cho tech stack/architecture; khóa Flutter `3.47.0` và Dart `3.13.0` qua FVM, pubspec và CI; chuẩn hóa lệnh Make/README. Mobile analyze sạch và 38 tests pass sau migration SDK/l10n.

- `MOB-P1-001`: thêm `AppConfig` qua DI, cấu hình mobile dev/staging/prod bằng dart-define JSON, kiểm tra HTTPS origin khi startup, lệnh Make/VS Code và hướng dẫn chạy. Staging có URL Render; dev có HTTPS proxy, CA chỉ tin cậy trong debug/dev, config iOS Simulator/Android Emulator/điện thoại LAN và Mailhog. Session/PIN tách theo env + API origin, phiên legacy cần login lại. Analyze sạch, 38 tests pass; Dart client xác nhận HTTPS/API/database local qua loopback/LAN, TLS từ chối CA/hostname sai; iOS Simulator build + launch dev pass; staging health/database up. Chưa tách native flavors; Android Emulator/thiết bị thật chưa kiểm chứng.

- `MOB-P1-001`: tách `EmailSender`/SMTP adapter khỏi auth outbox, preset Resend qua TLS :2465 cho Render, sender thử `onboarding@resend.dev`, idempotency khi retry, validation config và che lỗi/secret. Đổi vendor SMTP bằng env; thêm CLI kiểm tra kết nối và [runbook](../infrastructure/email.md). Backend build + 67 unit + 13 PostgreSQL integration tests pass; SMTP Mailhog register/verify/login/reset/revoke và connection probe pass. Chưa cấu hình key/deploy hoặc kiểm chứng inbox Resend. Sửa trạng thái task về `doing`, chờ E2E staging và biometric thiết bị thực.

## 2026-09-22

- `MOB-P1-001` UI: email-first theo mẫu, account cũ → password, account mới → đăng ký + mã verify tự gửi; quên password chỉ ở bước login. Thêm contract/API email-step có rate limit/no-store; cập nhật ADR về enumeration. 41 backend unit + 13 integration tests pass.

- `MOB-P1-001`: màn email auth/verify/reset, secure session, PIN 6 số (PBKDF2 + giới hạn sai bền vững), biometric opt-in, lifecycle privacy cover và quản lý phiên. DI abstract, l10n vi/en; 33 unit/widget tests + analyze xanh, build Android debug/iOS simulator pass. Cập nhật Android toolchain cho plugins và CocoaPods. [Thiết kế/giới hạn](../architecture/mobile-auth.md).

- `BE-P1-001`: cho phép login khi email chưa xác thực; giữ verify email độc lập và không tự đổi emailVerifiedAt khi login/reset. Cập nhật regression tests, contract và ADR 009.

## 2026-09-21

- `BE-P1-001`, `BE-P1-002`: auth `/api/v1` email/password (Argon2id), verify/reset single-use, encrypted SMTP outbox/retry; opaque session 7 ngày, list/revoke/logout, rate limit PostgreSQL IP/email. Reset/session mutations khóa User và audit cùng transaction. Migration + OpenAPI + ADR 009/threat model/runbook/CI cập nhật. 37 unit + 12 HTTP/PostgreSQL tests, upgrade/collision regression và SMTP Mailhog smoke pass. Chưa deploy; cần AUTH_SECRET_KEY/SMTP trước rollout. Dependency audit hiện hữu còn 4 high, ghi trong threat model.

- `MOB-P1-010` splash: motion ba nhịp từ PNG gốc trong 1,8 giây, halo nhẹ và thu nhỏ/fade out; copy mới “Your money. Your freedom.”, hỗ trợ giảm chuyển động và chữ lớn.

- `MOB-P1-010`: gắn AppIcon iOS, launcher legacy/adaptive Android từ PNG chính thức; symbol nguyên bản cho splash Flutter/home, wordmark/tagline qua l10n. Thêm script tái sinh asset từ source + token; analyze và widget tests pass. Chưa smoke test launcher trên device/simulator.

- `INF-P0-004`: provision staging live — API Render `https://freeva-api-staging.onrender.com` (health + DB up), admin Vercel `https://freeva-personal-finance-management.vercel.app`; checklist [staging.md](../infrastructure/staging.md) tick; URL ghi STATUS.
- **Phase 0 closed** (option B): residual crash monitoring chấp nhận — vendor dự kiến Sentry, SDK = `INF-P1-001` (DECISIONS-OPEN #9). Backlog P0 = 25/25; mở Phase 1.

## 2026-09-18

- Staging: chốt stack **Render** (API+Postgres) + **Vercel** (web-admin); thêm `render.yaml`, `apps/web-admin/vercel.json`, [staging.md](../infrastructure/staging.md), task `INF-P0-004`. Production hoster vẫn TBD tới Store (region VN).
- DECISIONS-OPEN #5: chốt region dữ liệu production primary **Việt Nam**; cập nhật privacy/ToS nháp, ADR 005, environments, threat model, STATUS.
- Brand: chốt UI design system board (`docs/brand/ui-design-system.png`); thêm `docs/brand/README.md` (logo, tagline, palette tóm tắt)
- Brand: thêm asset PNG từ board — `freeva-brand-symbol.png`, `freeva-logo-lockup.png`, `freeva-app-icon.png`; cập nhật `docs/brand/README.md`.
- Backlog: brand asset → Phase 1 (`MOB-P1-010`, `WA-P1-001`); Phase 0 = 24/25 (còn staging provision).

## 2026-09-17

- `QA-P0-002`: thêm fixture JSON versioned và Jest contract test cho transfer hai leg cân bằng, lỗi cấu trúc/dấu/group/type và FX exact; ghi rõ rounding/ledger còn `BE-P1-005`. Phase 0 backlog đạt 24/24; phase gate vẫn pending theo STATUS.

- `WA-P0-002`: thêm `POST /api/admin/user-lookups` và form Next admin; opaque Bearer staff từ env, exact lookup email/UUID, response hồ sơ tối thiểu, không dashboard/dữ liệu tài chính. Ghi `staff.user_lookup` cho success/không tìm thấy và fail closed khi audit lỗi. OpenAPI/threat model/docs cập nhật; single-staff credential chỉ dùng P0 nội bộ. Phase 0 đạt 23/24.

- `MOB-P0-004`: thêm Flutter `AnalyticsService`/debug implementation qua DI; catalog event typed với payload `schema_version: 1`, chỉ cho phép `transaction_created.type` theo enum và không nhận property tùy ý/PII. Chưa gắn vendor SDK hoặc phát event giả từ UI placeholder. Phase 0 đạt 22/24.

- `BE-P0-005`: sửa runbook restore vào database mới; thêm diễn tập tự dọn container/backup tạm. PostgreSQL 16.14 pass dump/restore, so sánh schema/toàn bộ dữ liệu và migration history, audit constraints và Prisma migration status. Phase 0 đạt 21/24; production backup policy còn mở.

- `BE-P0-004`: thêm schema/migration `AuditEvent`, CHECK actor/mã thao tác và index; ADR 008, data model, threat model. Kiểm chứng fresh deploy, upgrade bảo toàn dữ liệu và SQL regression trên PostgreSQL 16.14. Chưa service ghi event, integration, retention hoặc chống sửa/xóa.

## 2026-09-16

- `INF-P0-002`: xác minh ba job CI xanh trên `main` tại `e72ac63` ([run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189), chạy 2026-09-01). Cập nhật backlog thành done và ghi bằng chứng trong `docs/infrastructure/ci-cd.md`; không thay đổi workflow.

## 2026-09-01

- `PRD-P0-002`: bản nháp tiếng Việt Điều khoản dịch vụ và Chính sách bảo mật (`docs/legal/`); danh sách bên thứ ba dự kiến (không đặt tên bank/IAP; vendor/region TBD). Chưa review luật sư; export/xóa TK vẫn `BE-P1-010`.
- `PRD-P0-001`: persona P1 knowledge worker (beta 100%), thị trường VN, store listing 22–35; hộ gia đình giữ Phase 6 + workaround category/tag. Ba use case ghi chi UC-EXP-01/02/03 (`docs/product/use-cases.md`).

## 2026-08-31

- `SEC-P0-003`: checklist PII trong log (`docs/architecture/pii-log-checklist.md`); Pino redact nested 1–2 cấp + test hồi quy.
- `SEC-P0-001`: threat model STRIDE + inventory bề mặt Phase 0/1 (`docs/architecture/threat-model.md`).
- `BE-P0-001`: ADR 007 + ER; Prisma schema lõi (User, Currency, ví, danh mục, GD, FX, tag). Money = BigInt minor units. Chưa CRUD/seed.
- Dọn backlog Phase 0 cho khớp code: scaffold `done`; còn lại product/`INF-P0-002`.

## 2026-08-26

- Khởi tạo monorepo: docs, tasks, design tokens, compose, Nest health, Next admin, Flutter shell, CI.
