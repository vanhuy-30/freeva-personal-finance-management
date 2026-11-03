# Phase 3 — epic

[phase-03.md](../docs/product/phases/phase-03.md). Phase 2 đã đóng 2026-10-30; băm ticket khi làm epic. `Gate: v1`: mục tiêu (`BE-P3-E01`) và các ticket `P3-001`…`P3-011` thêm 2026-11-02 (gộp chức năng chồng chéo, bổ sung chức năng còn thiếu).

### BE-P3-E01 / MOB-P3-E01 — Mục tiêu (module 9)
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 9
- Gate: v1
- Depends: BE-P1-004, BE-P1-005, MOB-P1-006
- DoD: tên, số đích, số hiện tại, ngày đích, ví liên kết, mức đóng góp tháng, icon và màu bằng token. Có sẵn nhóm quỹ khẩn cấp, mua nhà, mua xe, du lịch, học tập, đám cưới, nghỉ hưu để chọn, user vẫn đặt tên riêng. Đóng góp hoặc rút tạo giao dịch đối ứng, hoặc một dòng audit nếu chỉ sửa số đã có. Công thức có test: đích 120000000, hiện có 40000000, còn 10 tháng → cần 8000000 mỗi tháng. Home hiện `hiện tại / đích` và phần trăm. Không tự chuyển tiền.
- Note: BE-P3-E01 xong 2026-11-02: `/api/v1/goals` (CRUD, presets, `contribute` / `withdraw` / `adjust`), transfer cân hai chân khi chọn ví nguồn, audit `goal.adjust`, công thức 8.000.000 có test, OpenAPI, export/xoá tài khoản. Kiến trúc: [goals.md](../docs/architecture/goals.md). MOB-P3-E01 (Home `hiện tại / đích`, màn mục tiêu) chưa làm.

### BE-P3-E02 / MOB-P3-E02 — Vay và công nợ (module 10)
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 10
- Gate: post-v1
- Depends: BE-P1-005
- DoD: loại thẻ, vay cá nhân, vay mua nhà, khác (cho mượn / đi mượn người quen bản nhẹ ở `BE-P3-007`). Có gốc, dư nợ, lãi suất, số tiền mỗi kỳ, tần suất, ngày đến hạn, ngày bắt đầu, ngày kết thúc. Màn hình tổng nợ, đã trả, còn lại. Mỗi lần trả là một giao dịch. Bộ test lãi dùng số cố định, không `double`. Không biến app thành sản phẩm cho vay.
- Note: BE-P3-E02 xong 2026-11-02: `/api/v1/loans` (CRUD, summary, schedule, payments, adjust), lãi dư nợ giảm dần bằng bigint có test (100tr, 12%/năm → lãi kỳ 1 = 1tr), mỗi lần trả tạo hai expense gốc/lãi, audit `loan.create` / `loan.adjust`, OpenAPI, export/xoá tài khoản. Kiến trúc: [loans.md](../docs/architecture/loans.md). Tồn đọng: phần gốc đang tính vào báo cáo chi tiêu (chưa tách); MOB-P3-E02 (màn tổng nợ) chưa làm.

### BE-P3-E03 / MOB-P3-E03 — Tiền gửi có kỳ hạn (module 11)
- Status: wont — gộp vào `BE-P4-E01` (2026-11-02)
- Module: 11
- Gate: post-v1
- Depends: BE-P1-004
- DoD: một khoản gửi gắn một ví, lãi có công thức và test, không cộng trùng số dư ví. Spec v1 không yêu cầu module này. Được đóng wont nếu beta không cần, và ghi quyết định vào module 11.

### BE-P3-E04 / MOB-P3-E04 — Dự báo số dư theo quy tắc
- Status: doing — BE xong 2026-11-03, MOB còn
- Module: 14, 15
- Gate: post-v1
- Depends: BE-P2-E01
- DoD: dự báo số dư từ số hiện tại cộng các định kỳ đã biết. Màn hình nêu giả định và cho sửa input. Khác forecast AI ở `BE-P5-E06`: không gọi model.
- Note: BE-P3-E04 xong 2026-11-03: `GET /api/v1/forecast` (`months`, `currencyCode`, `startingBalanceMinor`, `excludeRuleIds`), số dư từ ví không phải thẻ + định kỳ/hóa đơn thu chi, trả `assumptions`, có test số cố định, OpenAPI. Không quy đổi FX, không dự đoán chi tiêu ngoài định kỳ. Kiến trúc: [forecast.md](../docs/architecture/forecast.md). MOB-P3-E04 (màn hình giả định, sửa input) chưa làm.

## Gộp chức năng chồng chéo (thêm 2026-11-02)

### BE-P3-001 / MOB-P3-001 — Gộp hóa đơn vào giao dịch định kỳ
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 6, 8, 15
- Gate: v1
- Depends: BE-P2-E01, BE-P2-E03, BE-P2-E05
- DoD: một rule định kỳ có hai chế độ: tự ghi (như hiện tại) hoặc nhắc và chờ xác nhận (hóa đơn cũ). Chế độ nhắc có hạn trả, số cố định hoặc ước tính, nhắc trước N ngày qua hộp thư và push; "Đã trả" tạo hoặc trỏ tới giao dịch thật, quá hạn không tự ghi. Hóa đơn một lần là rule không lặp. Migration chuyển `Bill` sang rule, giữ liên kết giao dịch đã trả; API `/bills` trả 410 sau một bản chuyển tiếp. Mobile còn một màn "Định kỳ & hóa đơn". Lịch (module 15) chỉ là màn xem dữ liệu đó, không có dữ liệu riêng. Test: retry/sync không nhân đôi, xác nhận hai lần không ghi hai giao dịch.
- Note: BE-P3-001 xong 2026-11-02: `RecurringRule.mode` = `auto` | `remind`; hóa đơn là rule `remind` (một lần = `repeat: false`), `POST /recurring-transactions/{id}/confirm` trỏ hoặc tạo một expense mỗi hạn, retry/xác nhận hai lần không nhân đôi (test PostgreSQL), quá hạn tính khi đọc và không tự ghi, nhắc `bill_due` / `bill_overdue`, lịch đọc từ rule, `/bills` trả 410, migration `Bill` → rule giữ id/clientId và liên kết giao dịch đã trả. Kiến trúc: [bills.md](../docs/architecture/bills.md). Tồn đọng: chưa có hoàn tác xác nhận; bảng `Bill` chưa xóa; MOB-P3-001 (màn "Định kỳ & hóa đơn", bỏ `/me/bills`) chưa làm nên app hiện tại sẽ nhận 410 ở màn hóa đơn.

### MOB-P3-002 — Bổ sung thẻ soát tháng trên Tổng quan
- Status: todo
- Module: 14
- Gate: v1
- Depends: BE-P2-E08
- DoD: thẻ `NewMonthReviewCard` đã có (thu, chi tháng trước, chỉ hiện đầu tháng) thêm hai dòng: danh mục chi tăng nhiều nhất so với tháng trước nữa và ngân sách tháng trước có vượt không. Số lấy từ `GET /reports/month-review` và ngân sách, không AI, bỏ dòng khi thiếu dữ liệu. Đây là "insight" của v1.

### BE-P3-003 / MOB-P3-003 — Ngưỡng ngân sách mặc định 80 và 100
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 7, 17
- Gate: v1
- Depends: BE-P2-E02
- DoD: ngưỡng cảnh báo mặc định đổi từ `70, 80, 90, 100` thành `80, 100`; user vẫn thêm được tới 4 ngưỡng. Ngân sách đã lưu giữ nguyên ngưỡng cũ. Màu trạng thái (healthy / warning / critical / over) không đổi.
- Note: BE-P3-003 xong 2026-11-02: `DEFAULT_ALERT_THRESHOLDS` = `80, 100`, ngân sách đã lưu giữ ngưỡng cũ (mặc định chỉ áp ở code, không migration), OpenAPI/docs cập nhật. MOB-P3-003 (`defaultAlertThresholds` và gợi ý ngưỡng trên màn ngân sách) chưa làm.

### MOB-P3-004 — Ẩn quy đổi khi chỉ dùng một loại tiền
- Status: todo
- Module: 2, 14
- Gate: v1
- Depends: MOB-P2-013
- DoD: mục tỷ giá, tiền tệ hiển thị và dòng số quy đổi chỉ hiện khi user có ví, giao dịch hoặc khoản đầu tư ở từ hai loại tiền trở lên. Dữ liệu tỷ giá đã nhập không bị xóa.

## Chức năng bổ sung (thêm 2026-11-02)

### BE-P3-005 / MOB-P3-005 — Đối soát số dư ví
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 3, 4
- Gate: v1
- Depends: BE-P1-004, BE-P1-005
- DoD: trên chi tiết ví, user nhập số dư thực tế; app hiện chênh lệch và tạo một giao dịch điều chỉnh (`adjustment`) một leg. Điều chỉnh không tính vào thu/chi kỳ, ngân sách, tỷ lệ tiết kiệm; có trong lịch sử ví, export, sổ cái. Sửa hoặc xóa được như giao dịch thường. Ví thẻ tín dụng đối soát theo dư nợ. Test số dư sau điều chỉnh và báo cáo không đổi.
- Note: BE-P3-005 xong 2026-11-02: `POST /financial-accounts/{id}/reconcile` (tính chênh lệch ở server, `dryRun`, thẻ tín dụng theo dư nợ, idempotent theo `clientId`), `TransactionType` thêm `adjustment` (một leg, không danh mục/FX, chỉ tạo qua reconcile), không vào thu/chi, ngân sách, tỷ lệ tiết kiệm; báo cáo theo ví có `adjustmentMinor`; sửa/xóa qua `/transactions`; có trong export. Migration additive. Kiến trúc: [wallet-reconciliation.md](../docs/architecture/wallet-reconciliation.md). Tồn đọng: MOB-P3-005 chưa làm.

### BE-P3-006 / MOB-P3-006 — Nhắc ghi chi hằng ngày
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 17
- Gate: v1
- Depends: BE-P2-E05, BE-P2-015
- DoD: loại thông báo `daily_log`, mặc định tắt, user chọn giờ (theo múi giờ hồ sơ), tôn trọng giờ yên. Không gửi nếu hôm đó đã có giao dịch. Bấm thông báo mở thẳng màn ghi giao dịch. Nối công tắc "Nhắc ghi chi" đã có trên màn Thông báo. Tổng kết tuần/tháng trên cùng màn dùng `month_review` khi `MOB-P3-002` xong.
- Note: BE-P3-006 xong 2026-11-02: loại `daily_log` (mặc định tắt), `dailyLogEnabled` / `dailyLogTime` trên `/notification-preferences`, giờ theo múi giờ hồ sơ, không tạo nếu hôm đó (`occurredOn` = hôm nay) đã có thu/chi/chuyển (điều chỉnh số dư và giao dịch đã xóa không tính), giờ yên chặn, một hàng mỗi ngày, push vi/en không có số tiền. OpenAPI, export cập nhật. Kiến trúc: [notifications.md](../docs/architecture/notifications.md). Tồn đọng: MOB-P3-006 (công tắc, chọn giờ, bấm thông báo mở màn ghi theo `kind = daily_log`) chưa làm; `month_review` vẫn khóa.

### BE-P3-007 / MOB-P3-007 — Cho mượn và đi mượn
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 10
- Gate: v1
- Depends: BE-P1-004, BE-P1-005
- DoD: ghi khoản cho mượn (tiền ra khỏi ví thành khoản phải thu) hoặc đi mượn (tiền vào ví thành khoản phải trả) với tên người, số tiền, ngày, hạn tùy chọn, ghi chú. Trả hoặc thu một phần nhiều lần, tất toán. Không phải thu/chi, không tính ngân sách. Phải thu cộng tài sản, phải trả cộng nợ trên Tổng quan và tài sản ròng. Danh sách "Ai nợ mình / Mình nợ ai" kèm tổng. Nhắc khi tới hạn qua loại `debt`. Không lãi suất (vay có lãi là `BE-P3-E02`).
- Note: BE-P3-007 xong 2026-11-02: `/api/v1/personal-debts` (CRUD, `summary` ai nợ mình / mình nợ ai, `payments` trả một phần nhiều lần, tất toán), tiền di chuyển bằng giao dịch `debt` một chân (ngoài thu/chi, ngân sách, tỷ lệ tiết kiệm; có trong số dư ví, export, sổ cái), phải thu vào tài sản, phải trả vào nợ của `/reports/net-worth`, nhắc `debt_due` / `debt_overdue` qua loại `debt`, audit `personal_debt.create`, OpenAPI, export/xoá tài khoản. Kiến trúc: [personal-debts.md](../docs/architecture/personal-debts.md). Tồn đọng: chưa xóa được khoản ghi nhầm đã có tiền chuyển; lưu trữ chỉ khi đã tất toán; app chưa biết loại giao dịch `debt` / `adjustment`; MOB-P3-007 chưa làm.

### BE-P3-008 / MOB-P3-008 — Hoàn tiền gắn khoản chi gốc
- Status: doing — BE xong 2026-11-03, MOB còn
- Module: 4, 7, 14
- Gate: v1
- Depends: BE-P1-005, BE-P2-E02
- DoD: từ một khoản chi, tạo hoàn tiền (một phần hoặc toàn bộ) vào một ví. Hoàn tiền trỏ về khoản chi gốc, cùng danh mục, trừ vào chi của danh mục và ngân sách tại kỳ của khoản chi gốc thay vì tính là thu nhập. Tổng hoàn không vượt khoản gốc. Xóa khoản gốc thì hỏi xử lý hoàn tiền đi kèm. Test bảng số báo cáo và ngân sách.
- Note: BE-P3-008 xong 2026-11-03: `POST /transactions/{id}/refunds` (loại `refund` một leg, `refundOfId`, cùng danh mục, cùng tiền tệ, idempotent theo `clientId`), tổng hoàn ≤ khoản gốc kể cả song song, báo cáo/ngân sách/ngưỡng trừ hoàn tiền theo kỳ khoản gốc, xóa gốc còn hoàn tiền → 409 `REFUND_EXISTS` trừ khi `refunds=cascade|keep`, OpenAPI, export/xoá tài khoản. Migration additive. Kiến trúc: [refunds.md](../docs/architecture/refunds.md). Tồn đọng: MOB-P3-008 chưa làm; app chưa biết loại `refund`; hoàn tiền khác tiền tệ chưa hỗ trợ.

### BE-P3-009 / MOB-P3-009 — Trả góp thẻ tín dụng
- Status: doing — BE xong 2026-11-03, MOB còn
- Module: 3, 4, 6
- Gate: v1
- Depends: BE-P2-E07, BE-P3-001
- DoD: chốt 2026-11-02 cách ghi một lần. Khoản mua là một khoản chi đủ số tiền vào ngày mua trên ví thẻ, tính vào báo cáo và ngân sách tháng mua; dư nợ thẻ tăng đủ số, khớp sao kê. Đổi khoản chi đó thành kế hoạch trả góp: số kỳ, số mỗi kỳ, kỳ đầu. Kế hoạch chỉ là lịch: "số phải trả kỳ này" của thẻ cộng phần trả góp kỳ đó, lịch hiện các kỳ còn lại. Trả thẻ là chuyển khoản ví → thẻ, không phải chi tiêu mới. Phí chuyển đổi hoặc lãi là khoản chi riêng (danh mục phí), không cộng vào khoản mua. Trả trước hạn hoặc hủy thì đóng lịch, khoản chi gốc không đổi. Test: tổng các kỳ bằng giá mua; báo cáo chỉ đếm khoản mua một lần; dư nợ giảm đúng khi trả từng kỳ.
- Note: BE-P3-009 xong 2026-11-03: `/card-installments` (tạo từ khoản chi trên ví thẻ, chi tiết kèm lịch, `due` theo khoảng ngày, `close`), chỉ là lịch nên báo cáo, ngân sách và dư nợ không đổi, kỳ cuối nhận phần dư để tổng bằng giá mua, xóa khoản chi tự đóng lịch, OpenAPI, export/xoá tài khoản. Migration additive. Kiến trúc: [card-installments.md](../docs/architecture/card-installments.md). Tồn đọng: MOB-P3-009 chưa làm; chưa nhắc đến hạn kỳ trả góp; chưa tạo lại kế hoạch sau khi đóng.

### BE-P3-010 / MOB-P3-010 — Xuất CSV
- Status: doing — BE xong 2026-11-03, MOB còn
- Module: 20, 21
- Gate: v1
- Depends: BE-P1-010
- DoD: xuất giao dịch (lọc theo khoảng ngày, ví) ra CSV UTF-8 có BOM để Excel đọc đúng tiếng Việt. RFC 4180, chặn công thức (`=` `+` `-` `@` đầu ô). Số tiền dạng số không định dạng theo locale, kèm cột tiền tệ. Không thay export JSON (bản sao lưu).
- Note: BE-P3-010 xong 2026-11-03: `GET /transactions/export.csv` (cùng bộ lọc danh sách, UTF-8 BOM, RFC 4180, CRLF, chặn `= + - @`, `amount` thập phân bigint kèm cột `currency`, cũ → mới, tối đa 50 000 dòng), audit `user.transactions_export` fail closed, OpenAPI. Không migration. Kiến trúc: [transactions-csv-export.md](../docs/architecture/transactions-csv-export.md). Tồn đọng: MOB-P3-010 chưa làm (nút xuất, chia sẻ file); chưa có bộ lọc theo ví ở mức tên, chỉ theo `accountId`.

### BE-P3-011 / MOB-P3-011 — Nhập CSV từ app khác
- Status: doing — BE xong 2026-11-03, MOB còn
- Module: 13
- Gate: v1
- Depends: BE-P1-005, BE-P1-009, BE-P3-010
- DoD: nhập CSV/Excel: xem trước, map cột (ngày, số tiền, loại, danh mục, ví, ghi chú), map danh mục và ví về dữ liệu Freeva. Có preset cho Money Lover, Sổ thu chi MISA và file mẫu Freeva (trùng định dạng `BE-P3-010`). Kết quả từng dòng; trùng với giao dịch đã có thì đánh dấu, không ghi đè im lặng. Hoàn tác cả lô. Sao kê ngân hàng PDF/Excel vẫn là `BE-P5-E01`.
- Note: BE-P3-011 xong 2026-11-03: `POST /transactions/import/preview` (không ghi), `POST /transactions/import` (một transaction, `clientId` tất định theo `batchClientId`, replay 200), `GET`/`POST …/{id}/undo`. Preset Freeva/Money Lover/MISA/custom, map ví và danh mục, kết quả từng dòng, trùng → `duplicate` và bỏ qua (không ghi đè), chuyển khoản ghép hai dòng, hoàn tác bỏ qua giao dịch đã sửa hoặc có hoàn tiền/trả góp. Migration additive. Kiến trúc: [transaction-import.md](../docs/architecture/transaction-import.md). Tồn đọng: MOB-P3-011 chưa làm; chưa nhập Excel (.xlsx, theo quyết định chỉ CSV trước); header Money Lover/MISA chưa kiểm với file thật; chưa nhập nhãn; chuyển khoản khác tiền tệ chưa ghép; tối đa 2 000 dòng mỗi lần.

### DS-P3-012 / BE-P3-012 / MOB-P3-012 — Onboarding chỉ hỏi điều dùng được
- Status: doing — DS xong 2026-11-03, BE xong 2026-11-03, MOB còn
- Module: 1, 2, 7, 9
- Gate: v1
- Depends: DS-P2-004, BE-P2-E02, BE-P3-E01
- DoD: chốt 2026-11-02. Sau tạo tài khoản chỉ còn ba câu, đều bỏ qua được, rồi tới bước ví và số dư như cũ:
  1. **Mục tiêu sử dụng** (chọn tối đa 2): Quản lý chi tiêu, Tiết kiệm, Quản lý ngân sách. Chi tiêu → khối "Chi tháng" đầu Tổng quan và gợi ý bật nhắc ghi chi (`BE-P3-006`) sau giao dịch đầu. Tiết kiệm → khối mục tiêu đầu Tổng quan. Ngân sách → khối ngân sách đầu Tổng quan và màn gợi ý ngân sách bên dưới.
  2. **Thu nhập hàng tháng** (không bắt buộc): lưu `monthlyIncomeMinor` trên hồ sơ, sửa hoặc xóa được ở Cá nhân. Dùng để gợi ý ngân sách và hiện phần tiết kiệm so với thu nhập. Không log, có trong export, xóa cùng tài khoản.
  3. **Mục tiêu tiết kiệm** (không bắt buộc): tên hoặc nhóm có sẵn, số đích, ngày đích. Tạo một mục tiêu thật (`BE-P3-E01`) và hiện "cần X mỗi tháng"; có thu nhập thì hiện thêm phần trăm thu nhập.
  Có thu nhập thì hiện một màn gợi ý ngân sách (thu nhập trừ số cần tiết kiệm mỗi tháng; quy tắc khi không có mục tiêu chốt ở thiết kế), "Dùng mức này" tạo ngân sách tháng, "Để sau" không tạo gì. Bỏ câu thói quen và nhịp xem lại; migration xóa `trackingHabit`, `reviewCadence`, `onboardingBudgetMinor`; mục tiêu cũ `emergency` gộp vào Tiết kiệm, `debt` và `understand` bỏ; export cập nhật. Thiết kế vẽ lại trên canvas nhóm A trước khi code.
- Note: BE-P3-012 xong 2026-11-03: `User.monthlyIncomeMinor` (số nguyên dương, minor unit), `PATCH /profile/onboarding` chỉ nhận `goals` (`track|save|budget`, tối đa 2) và `monthlyIncomeMinor`, `PUT /profile/monthly-income` đặt/sửa/xóa (`null`), `GET /profile` và export trả `monthlyIncomeMinor`; migration xóa `trackingHabit`, `reviewCadence`, `onboardingBudgetMinor`, đổi `emergency` → `save`, bỏ `debt`/`understand`. OpenAPI, test đơn vị và PostgreSQL cập nhật. Tồn đọng: màn onboarding hiện tại trên app còn gửi `trackingHabit`/`reviewCadence`/`budgetMinor` nên nhận 400 tới khi làm MOB-P3-012; gợi ý ngân sách (thu nhập − cần để dành, hoặc thu nhập × 80%) là logic client; tạo mục tiêu từ câu 3 dùng `/goals` có sẵn; bật nhắc ghi chi dùng `BE-P3-006`.


### INF-P3-001 — Kiểm tra format Dart trong CI mobile
- Status: done — 2026-11-02
- Module: —
- Gate: —
- Depends: INF-P0-002
- DoD: job `mobile` chạy `dart format --output=none --set-exit-if-changed` trên `lib test tool`, trừ file sinh tự động (`*.g.dart`, `*.config.dart`, `*.freezed.dart`: có gate riêng, `tokens.g.dart` cấm format tay), sau `flutter pub get` và trước codegen. `apps/mobile` được format một lần (62 file, thêm ngoặc cho 3 câu `if` để qua `curly_braces_in_flow_control_structures`). Analyze và test vẫn xanh.
