# Phase 2 — epic

Điều kiện hoàn thành: [phase-02.md](../docs/product/phases/phase-02.md). Phase 1 gate sổ cái **closed** 2026-10-21 — được băm ticket triển khai khi làm epic. `Gate: v1` vẫn là điều kiện product v1.

### DS-P2-001 — Design system v2: spec và token
- Status: done
- Module: —
- Gate: post-v1
- Depends: DS-P0-001
- DoD: [design-system.md](../docs/brand/design-system.md) chốt nguyên tắc, foundations, components, trạng thái, patterns, guidelines. `tokens.json` có ba tầng primitive → semantic (light/dark) → component cùng typography, space, radius, size, elevation, motion. Key `color.*` giữ nguyên ([ADR 012](../docs/architecture/adr/012-design-tokens-v2.md)). `tokens.css` sinh bằng script; `pnpm check` trong `packages/design-tokens` xanh (tương phản AA cả hai mode).

### DS-P2-002 — Flutter theme và component nền
- Status: done
- Module: —
- Gate: post-v1
- Depends: DS-P2-001
- DoD: sinh Dart từ `tokens.json` (không chép tay hex). `AppTheme` light/dark dùng semantic token và `ThemeExtension`. Inter đóng gói trong app. Thêm `lucide_icons_flutter` 4.0.1 và thay các `Icons.*`. Component trong `lib/core/widgets/`: nút, trường nhập, bàn phím số tiền, chip, segmented, bottom nav, thanh trên, sheet, thẻ, dòng giao dịch, toast, banner, hộp thoại, trạng thái trống có animation tự vẽ, skeleton. Đủ 6 trạng thái. Trang gallery chỉ ở debug và golden test light/dark.

### DS-P2-003 — Refactor màn hình Phase 1 theo design system
- Status: done
- Module: —
- Gate: post-v1
- Depends: DS-P2-002
- DoD: Tổng quan theo [B-overview.md](../docs/brand/patterns/B-overview.md) (đủ 8 trạng thái; ẩn số dư chỉ ẩn số dư); Ví theo [D-wallets.md](../docs/brand/patterns/D-wallets.md); Danh mục theo [E-categories.md](../docs/brand/patterns/E-categories.md) (màu và biểu tượng mới cần task BE riêng); Báo cáo theo [F-reports.md](../docs/brand/patterns/F-reports.md) (chuỗi xu hướng, kỳ năm cần task BE riêng; khối ngân sách theo `BE-P2-E02`); Cá nhân/Cài đặt theo [G-profile-settings.md](../docs/brand/patterns/G-profile-settings.md) (trường hồ sơ mới, đổi email/mật khẩu, liên kết, xoá tài khoản, API góp ý cần task BE riêng); Đồng bộ theo [H-sync.md](../docs/brand/patterns/H-sync.md) (giữ bản trên máy và mã lý do lỗi cần task BE riêng). Bottom nav chỉ ở màn gốc của tab. Theo thứ tự Tổng quan → Ghi giao dịch → Danh sách giao dịch → Ví → Báo cáo → Cá nhân/Cài đặt/Giới thiệu/Đăng nhập/Khoá. Chỉ đổi View và widget, không đổi ViewModel/use case. Mỗi màn một PR. Không còn hex rời hay `Icons.*` trong `lib/features`. Đo lại ghi chi < 10 giây (QA-P1-001). Chạy được ở màn 320 pt và cỡ chữ 1.3×.
- Note: B/D/E/F/G/H xong theo [design-progress.md](../docs/brand/design-progress.md). C thuộc `DS-P2-005`; A thuộc `DS-P2-004`. Phần còn lại: ngân sách `BE-P2-E02`, thông báo đẩy `BE-P2-E05`, xoá tài khoản `MOB-P2-011`, mục tiêu/đổi email ở `DS-P2-004`; nút Cập nhật/Sửa sync và vài lệch canvas ghi trong pattern sau `DS-P2-006`.

### DS-P2-004 — Onboarding và tài khoản theo thiết kế nhóm A
- Status: todo
- Module: 1, 24
- Gate: post-v1
- Depends: DS-P2-002
- DoD: luồng và màn theo [A-onboarding-auth.md](../docs/brand/patterns/A-onboarding-auth.md): Welcome → Mục tiêu (tối đa 2) → Thói quen → Ngân sách (ẩn hoặc lưu tạm nếu chưa có `BE-P2-E02`) → Tạo tài khoản → Thiết lập tài chính (không bắt buộc) → Trang chính có checklist. Đăng nhập email + mật khẩu một màn. PIN không chặn đường vào app. Deep link xác nhận email / đặt lại mật khẩu và Google/Apple mobile tách task BE/MOB riêng khi làm.
- Tiến độ: A1 xong 2026-10-23 (đăng nhập, đăng ký + `termsAccepted`, xác nhận email, quên/đặt lại mật khẩu, PIN tuỳ chọn, Mở khoá). A2a xong 2026-10-23 (Welcome, Tạo tài khoản Freeva, Mục tiêu, Thói quen, Ngân sách lưu trên máy; `PATCH /profile/onboarding`; màn giới thiệu cũ bị bỏ). A2b xong 2026-10-23 (Thiết lập tài chính, checklist "Bắt đầu nào", tên ở màn Mở khoá). Câu trả lời và số ngân sách đầu gắn với tài khoản, kể cả export: `BE-P2-012`. Còn trong task này: dùng mục tiêu để sắp khối Tổng quan, nối ngân sách vào `BE-P2-E02`. Việc tách riêng: link xác nhận email / đặt lại mật khẩu mở thẳng app (BE gửi link, MOB deep link; nối vào `AuthViewModel.startReset`), Google/Apple trên mobile, nơi xác nhận lại email trong Cá nhân (cần cờ `emailVerified` trong hồ sơ).

### DS-P2-005 — Giao dịch theo thiết kế nhóm C
- Status: done
- Module: 4, 5
- Gate: post-v1
- Depends: DS-P2-002
- DoD: màn và luồng theo [C-transactions.md](../docs/brand/patterns/C-transactions.md): danh sách có chip lọc và tổng theo bộ lọc, tìm không dấu, sheet bộ lọc, trạng thái không kết quả, sheet chi tiết (sửa, sao chép, xoá có Hoàn tác), mục Đã xoá, ghi chi/thu với sheet danh mục và sheet nhãn, chuyển ví khác tiền tệ có tỷ giá + thời điểm. Lọc nhiều ví/danh mục, lọc nhãn, tìm theo cửa hàng và tổng theo bộ lọc tách task BE/MOB riêng khi làm.

### BE-P2-E01 / MOB-P2-E01 — Giao dịch định kỳ (module 6)
- Status: done
- Module: 6
- Gate: post-v1
- Depends: BE-P1-005, MOB-P1-004
- DoD: chu kỳ ngày, tuần, tháng, năm và custom. Có số tiền, ví, danh mục, ngày bắt đầu, ngày kết thúc, lần chạy tới, bật/tắt. Đến hạn tạo giao dịch đúng một lần; retry và sync không nhân đôi. Tắt thì không tạo thêm. Chuyển khoản định kỳ vẫn là hai leg cân bằng. Test tháng không có ngày 31.
- Note: API + worker + OpenAPI + export/xóa tài khoản; mobile danh sách/form từ Cá nhân và `POST .../run` lúc vào app. Kiến trúc: [recurring.md](../docs/architecture/recurring.md).

### BE-P2-E02 / MOB-P2-E02 — Ngân sách (module 7)
- Status: done
- Module: 7
- Gate: v1
- Depends: BE-P1-005, BE-P1-006, MOB-P1-006
- DoD: ngân sách tổng tháng và theo danh mục, minor units. Đã chi chỉ tính expense chưa xóa; transfer và income không tính. Mức `<70%` healthy, `70–90%` warning, `>90%` critical, `>100%` over. Ngưỡng cảnh báo mặc định 70, 80, 90, 100 và user sửa được. Home hiện thanh `đã chi / hạn mức` khi có ngân sách. Test một bảng số. Gửi push thuộc `BE-P2-E05`.
- Note: API `GET/PUT/DELETE /budgets/current` với template mặc định + override theo tháng (`applyTo`/`on`/`isOverride`), OpenAPI, export/xóa tài khoản; mobile `/budgets` (Mọi tháng / Tháng này), Báo cáo tháng, thanh Tổng quan, nối draft onboarding. Kiến trúc: [budgets.md](../docs/architecture/budgets.md).

### BE-P2-E03 / MOB-P2-E03 — Hóa đơn (module 8)
- Status: done
- Module: 8
- Gate: post-v1
- Depends: BE-P2-E01
- DoD: hóa đơn một lần hoặc gắn một định kỳ. Có hạn, số cố định hoặc ước tính. Đánh dấu đã trả thì trỏ tới một giao dịch. Quá hạn không tự tạo giao dịch.
- Note: API `GET/POST /bills`, `GET/PATCH/DELETE /bills/:id`, `POST .../pay` và `.../unpay` (chỉ gắn giao dịch có sẵn); OpenAPI; export/xóa tài khoản. Mobile `/me/bills` từ Thiết lập tài chính. Quá hạn tính khi đọc theo timezone hồ sơ. Nhắc đẩy `BE-P2-E05`; lịch tháng `MOB-P2-E04`. Kiến trúc: [bills.md](../docs/architecture/bills.md).

### MOB-P2-E04 / BE-P2-E04 — Lịch tài chính bản đầu (module 15)
- Status: done
- Module: 15
- Gate: post-v1
- Depends: BE-P1-005, BE-P2-E01
- DoD: một tháng hiện giao dịch đã ghi, lần chạy định kỳ và hạn hóa đơn theo timezone hồ sơ.
- Note: API `GET /api/v1/calendar?month=YYYY-MM` (timezone hồ sơ; transfer một mục; định kỳ chiếu từ `nextExecutionDate`; hóa đơn `overdue` khi đọc); OpenAPI. Mobile `/me/calendar` từ Thiết lập tài chính. Phase 3 (nợ/thẻ/mục tiêu) ngoài epic. Kiến trúc: [calendar.md](../docs/architecture/calendar.md).

### BE-P2-E05 / MOB-P2-E05 — Thông báo và giờ yên (module 17)
- Status: done
- Module: 17
- Gate: post-v1
- Depends: BE-P2-E02
- DoD: từng loại bật tắt được: ngân sách 80% và vượt, nhắc đóng góp mục tiêu, nợ đến hạn, thẻ đến hạn, định kỳ sắp chạy, soát tháng, insight mới, cảnh báo bảo mật. Giờ yên và timezone hồ sơ được tôn trọng. Nội dung không đưa số dư đầy đủ nếu câu thông báo không cần. Chưa có module nguồn thì loại đó tắt và không gửi.
- Note: Hộp thư in-app + preference API + worker/evaluate; budget ≥80 và recurring ngày trước lần chạy; security trên máy; giờ yên. Push FCM tách `BE-P2-015`. Kiến trúc: [notifications.md](../docs/architecture/notifications.md).

### BE-P2-E06 — Mở rộng báo cáo và search (14, 19)
- Status: done
- Module: 14, 19
- Gate: post-v1
- Depends: BE-P1-007, BE-P1-008
- DoD: so cùng kỳ trước, savings rate = tiết kiệm / thu nhập, xu hướng thu chi cho 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm và toàn bộ. Top merchant chỉ khi `BE-P1-012` đã có merchant.
- Note: `GET /reports/cashflow` thêm `savingsRateBps`, `comparison` (kỳ liền trước cùng loại), `topMerchants`; `GET /reports/series?window=7d|30d|3m|6m|1y|all`. Search merchant đã có từ `DS-P2-005` — không endpoint search mới. OpenAPI + unit/integration. Kiến trúc: [reports.md](../docs/architecture/reports.md).

### BE-P2-E07 / MOB-P2-E07 — Vòng đời thẻ tín dụng
- Status: done
- Module: 3
- Gate: post-v1
- Depends: BE-P1-004, BE-P1-007
- DoD: từ hạn mức và số dư suy ra dư nợ và hạn mức còn. Giữ ngày chốt và ngày đến hạn 1–28. Thêm số trả tối thiểu. Cảnh báo sắp đến hạn, dư nợ cao và sắp vượt hạn mức. Không tự trả nợ.
- Note: `minimumPaymentMinor` trên ví credit; OpenAPI + export; kind `card` mở khóa (đến hạn 0–3 ngày, dùng ≥70% / ≥90%); form và chi tiết thẻ trên mobile; không tạo giao dịch trả nợ.

### BE-P2-E08 / MOB-P2-E08 — Soát tháng
- Status: todo
- Module: 14
- Gate: post-v1
- Depends: BE-P1-007
- DoD: một bản cho tháng đã chọn: thu, chi, tiết kiệm, savings rate, top 3 danh mục. Mọi số lấy từ báo cáo, không tính lại ở client. Phần lời AI gắn ở `BE-P5-E04`; bản không AI vẫn đủ số.

### BE-P2-E09 / MOB-P2-E09 — Giờ giao dịch
- Status: todo
- Module: 4
- Gate: post-v1
- Depends: DS-P2-005
- DoD: giao dịch lưu thêm giờ (tuỳ chọn) trong múi giờ hồ sơ; `occurredOn` vẫn là ngày lịch cho báo cáo. API, OpenAPI, sync và form ghi/sửa (ô Thời gian có giờ như thiết kế C2.3, chi tiết "Hôm nay, 12:40"). Tách ra từ nhóm C theo quyết định 2026-10-22.

## Việc bổ sung (2026-10-26)

Phase 1 giữ đóng. Các ticket dưới đây không đổi số 28/28.

### BE-P2-010 / MOB-P2-010 — Khóa thu/chi theo kind
- Status: todo
- Module: 4, 5
- Gate: post-v1
- Depends: BE-P1-011, MOB-P1-004, MOB-P1-005
- DoD: Khi ghi hoặc sửa, chi chỉ nhận danh mục `expense` hoặc `both`; thu chỉ nhận `income` hoặc `both`. Chuyển khoản không có danh mục. API từ chối kind lệch (không ghi một phần). `both` vẫn hiện ở cả hai phía. Màn Danh mục (tab Chi · Thu) và form ghi đã lọc trên client — không làm lại hai màn đó. Form đang mở nếu đổi loại mà danh mục không còn hợp thì bỏ chọn và không lưu. Xung đột kind trả lỗi có chữ vi/en, không log tên danh mục hay số tiền. OpenAPI và test owner/kind. Cập nhật câu “một cây” trong [spec-alignment](../docs/product/spec-alignment.md) và [module 5](../docs/product/modules/05-categories.md) khi xong.

### INF-P2-001 — Postgres staging miễn phí thay Render
- Status: todo
- Module: 26
- Gate: ops
- Depends: INF-P0-004
- DoD: DB staging trên Render (plan free trong `render.yaml`) đã hết hạn. Chọn một Postgres miễn phí, chạy được Prisma migrate, chỉ cho dữ liệu staging. `DATABASE_URL` đặt trên dashboard host, không commit. API staging có thể giữ Render nếu web service còn sống; health `GET /api/health` trả `database=up` sau migrate. Không seed PII, không dùng làm production, không chốt vendor production (region VN vẫn là DECISIONS-OPEN #5). Cập nhật [staging.md](../docs/infrastructure/staging.md), `render.yaml` (bỏ DB Render đã chết), [DECISIONS-OPEN](../docs/project-state/DECISIONS-OPEN.md) #4 và URL trong [STATUS](../docs/project-state/STATUS.md). Ghi giới hạn plan miễn phí (ngủ, hết hạn, vùng) vào staging.md.

### MOB-P2-011 — Xuất và xóa tài khoản trên app
- Status: todo
- Module: 21
- Gate: post-v1
- Depends: BE-P1-010, MOB-P1-001
- DoD: Từ Hồ sơ, người dùng xuất được file JSON của `GET /api/v1/account/export` (chia sẻ hoặc lưu trên máy) và xóa được tài khoản bằng `DELETE /api/v1/account`. Xóa hỏi lại rõ, có hiệu lực ngay, không cửa sổ 30 ngày và không đòi mật khẩu — API hiện không nhận mật khẩu vì tài khoản OAuth có thể không có. Sau xóa thành công: xóa phiên, PIN và hàng đợi sync trên máy, về màn vào app. Lỗi mạng không xóa dữ liệu local và không báo đã xóa. Không log email, ghi chú hay số tiền. Chuỗi vi/en. Sửa câu trong app đang nói xuất/xóa là việc phát hành riêng. Không CSV, không API mới. Trường onboarding trong file export thuộc `BE-P2-012`; nút xuất lưu đúng body API trả về.

### QA-P2-001 — Rà soát hàng đợi offline giao dịch
- Status: todo
- Module: 20
- Gate: post-v1
- Depends: BE-P1-009, MOB-P1-008
- DoD: Đi lại hợp đồng [mobile-sync.md](../docs/architecture/mobile-sync.md) trên create, sửa, xóa, khôi phục: gộp mutation, giữ `clientId`, `applied`/`replayed` xóa khỏi hàng, `conflict` không ghi đè, đăng xuất xóa hàng, khóa PIN không xóa, banner và màn chọn bản. Ghi kết quả vào `mobile-sync.md`. Sửa lỗi làm sai hợp đồng đó (trùng giao dịch, ghi đè im lặng, hàng sống sót sau đăng xuất, số dư chờ sync hiện như đã chốt). Không thêm sync ví/danh mục, không CRDT, không pull cursor, không đổi API.

### BE-P2-012 / MOB-P2-012 — Gắn câu trả lời đầu vào tài khoản
- Status: todo
- Module: 2, 21
- Gate: post-v1
- Depends: DS-P2-004, BE-P1-010
- DoD: Mục tiêu, thói quen và nhịp xem lại đã lưu bằng `PATCH /profile/onboarding` phải đọc lại được trên hồ sơ, có trong `GET /account/export`, và hiện lại khi đăng nhập máy khác. Số ngân sách tháng nhập lúc đầu lưu trên user, integer minor units theo tiền tệ mặc định của tài khoản, không chỉ trong preference máy; đổi tiền tệ hồ sơ không tự quy đổi số này. Bỏ qua bước thì không ghi đè giá trị đang có. Xóa tài khoản xóa cùng user. Không log số ngân sách. PIN, theme và cờ ẩn số dư vẫn chỉ trên máy. Chưa làm thanh ngân sách hay ngưỡng — đó là `BE-P2-E02`. Chưa sắp khối Tổng quan theo mục tiêu — phần đó ở lại `DS-P2-004`.

### BE-P2-013 / MOB-P2-013 — Quy đổi để hiển thị trên tổng quan và chi tiết
- Status: todo
- Module: 3, 4, 14
- Gate: post-v1
- Depends: BE-P1-004, BE-P1-005, BE-P1-007, MOB-P1-003, MOB-P1-006
- DoD: Số lưu trên ví và giao dịch giữ nguyên tiền tệ gốc (minor units, không `double`). Tổng quan cộng tài sản, nợ, ròng, thu và chi của tháng sau khi quy về một tiền tệ hiển thị người dùng chọn trên màn đó; lựa chọn lưu trên tài khoản, mặc định bằng tiền tệ hồ sơ. Chi tiết ví và chi tiết giao dịch hiện số gốc kèm số quy về tiền tệ mặc định trong hồ sơ, cùng tỷ giá và `quotedAt`. Tỷ giá do người dùng nhập, lưu rate + thời điểm; không gọi nguồn giá ngoài (DECISIONS-OPEN #6 vẫn mở). Đổi đúng minor unit thì mới cộng vào tổng; lệch lẻ hoặc thiếu tỷ giá thì giữ dòng gốc và không bịa số, không trộn vào tổng đã quy đổi. Cùng tiền tệ thì không cần tỷ giá. Báo cáo kỳ vẫn tách từng loại tiền. OpenAPI, test một bảng số, log không có số tiền. Khi xong, ghi ngoại lệ hiển thị này vào [ADR 006](../docs/architecture/adr/006-money-and-fx.md) và pattern [B-overview](../docs/brand/patterns/B-overview.md) (màn nhiều tiền tệ đang nói không quy đổi).

### BE-P2-014 / MOB-P2-014 — Mật khẩu tối thiểu 8 và kiểm tra email trên app
- Status: todo
- Module: 1
- Gate: post-v1
- Depends: BE-P1-001, MOB-P1-001
- DoD: Mật khẩu mới (đăng ký, đặt lại, đổi khi đã đăng nhập) tối thiểu **8** ký tự (tối đa 128), vẫn bắt buộc có ít nhất một chữ và một số; không trim. Đăng nhập chỉ kiểm tra độ dài trong khoảng 8–128 để mật khẩu cũ vẫn dùng được. Backend DTO, OpenAPI và test đổi từ 12 xuống 8. Mobile: `PasswordCheck`, use case, danh sách tick và chuỗi l10n vi/en ("Ít nhất 8 ký tự"). Trên app, trước khi gọi API: đăng ký, đăng nhập và quên mật khẩu từ chối email không đúng định dạng sau trim/lowercase; báo lỗi rõ bằng l10n, không gửi request. Backend vẫn là nguồn từ chối cuối. Không đổi Argon2id, không log mật khẩu hay email đầy đủ. Cập nhật [A-onboarding-auth](../docs/brand/patterns/A-onboarding-auth.md) và [mobile-auth](../docs/architecture/mobile-auth.md).

### BE-P2-015 / MOB-P2-015 — Đẩy thông báo qua FCM
- Status: todo
- Module: 17
- Gate: post-v1
- Depends: BE-P2-E05
- DoD: Firebase Cloud Messaging là nhà cung cấp push. App đăng ký token FCM theo phiên; đăng xuất và xóa tài khoản xóa token. Khi E05 tạo hàng hộp thư ngoài giờ yên, server gửi một push; trong giờ yên không gửi, hết giờ yên thì gửi một lần nếu hàng vẫn chưa đọc. Payload không có số dư, số tài khoản, email đầy đủ, tên rule hay id phiên. iOS đi qua FCM (APNs do Firebase giữ). Khóa Firebase chỉ trên dashboard / secret CI, không commit. Hộp thư và công tắc E05 giữ nguyên. Cập nhật [notifications.md](../docs/architecture/notifications.md) và câu push trong [mobile-privacy.md](../docs/architecture/mobile-privacy.md).
