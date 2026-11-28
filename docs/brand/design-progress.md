# Tiến độ thiết kế UI v2 — bàn giao giữa các phiên

Đọc file này trước khi tiếp tục thiết kế. Cập nhật mỗi khi chốt một nhóm.

- Spec: [design-system.md](design-system.md) · token: [`packages/design-tokens`](../../packages/design-tokens/)
- Canvas (riêng tư, của product owner): <https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>
- Bản sao nguồn canvas trong repo: [canvas/](canvas/) (`canvas.json` + mỗi artboard một `.dc.html`). Nếu canvas và repo lệch nhau: tài liệu và token trong repo thắng.
- Nhánh: `feat/DS-P2-001-design-system-v2`

## Quy tắc canvas (đặt 2026-11-17)

Canvas tổ chức **theo khu vực sản phẩm**, không theo đợt làm việc. Một màn chỉ có **một board**.

**Trang**
| Trang | Nội dung | Khối |
|---|---|---|
| 01–04 | Foundations, Tokens, Components, States | |
| 05 · Patterns | Mẫu dùng chung (Data display, Search, Form, Settings, Authentication) | |
| 06 · Onboarding và tài khoản | Đăng ký, hỏi nhanh, PIN, Face ID, quên mật khẩu | A1, A2 |
| 07 · Tổng quan, báo cáo, dự báo | Tổng quan và trạng thái, báo cáo, ngân sách, lịch, soát tháng, hộp thư, phân tích | B, F, N, S |
| 08 · Giao dịch | Danh sách, tìm, lọc, chi tiết, ghi chi/thu/chuyển, gợi ý danh mục | C1, C2, R |
| 09 · Ví và tài sản | Ví, thẻ, khớp số dư, hoàn tiền, trả góp, đầu tư, tài sản ròng | D, M, P, Q |
| 10 · Danh mục | Danh mục và danh mục con | E |
| 11 · Mục tiêu, vay nợ, định kỳ | Mục tiêu, người quen, khoản vay, định kỳ và hóa đơn | I, K, L, T |
| 12 · Cá nhân, dữ liệu, đồng bộ | Cá nhân, xuất/nhập, gợi ý tự động, đồng bộ | G, O, U, H |
| 13 · Guidelines | IA, truy cập, chuyển động, giọng văn | |

**Tên board** (tiêu đề trên canvas): `<Khối> · <số>. <Tên màn>` rồi tuỳ chọn ` · <trạng thái>`.
- Trạng thái viết thường: `· trống`, `· lỗi`, `· ẩn số dư`, `· có mục tiêu`. Loại thành phần trong ngoặc: `(sheet)`, `(popup)`.
- Số là **mã cố định**, không đánh lại khi bỏ hay gộp board (tài liệu pattern và task tham chiếu `C2.4`, `M.3`…). Chỗ trống do gộp thì chấp nhận; không dồn số.
- Biến thể của một màn thêm hậu tố chữ: `1b`, `1c` (ví dụ `C2 · 1b. Ghi thu`). Màn mới hẳn thì lấy số kế tiếp.
- Không đưa số đợt, ngày chốt hay chữ "Phase", "bản đang chạy", "mới" vào tên board.

**Tên file**: `<Khu vực><Màn><Trạng thái>.dc.html`, không dấu, PascalCase. Tiền tố khu vực: `Ob` onboarding, `Au` đăng nhập/đăng ký, `B` Tổng quan, `Tx` giao dịch, `W` ví, `Cat` danh mục, `Rep` báo cáo, `Me` cá nhân, `Sync`, `Goal`, `Debt`, `Loan`, `Rec` định kỳ, `P` đầu tư, `Ins` phân tích, `Import`. Trạng thái là hậu tố: `Empty`, `Hidden`, `Error`. Không dùng hậu tố số để phân biệt đời (`...3`).

**Khi một màn đổi**: sửa tại chỗ board hiện có (hoặc thay nội dung), không tạo bản song song và để bản cũ. Board cũ không còn dùng thì xoá luôn và nối lại mọi link trỏ tới nó. Chỉ thêm board mới khi là **trạng thái hoặc biến thể mới** của màn đó.

**Vị trí**
- Một khối = một tiêu đề lớn (`title1`) + một hoặc nhiều hàng; tiêu đề cách hàng đầu 300 px.
- Hàng sắp theo luồng, từ trái sang phải; cách nhau 70 px; **không để ô trống** giữa hai board; tối đa 10 board một hàng, dài hơn thì xuống hàng.
- Hàng dưới cách hàng trên 120 px (tính theo board cao nhất); khối kế tiếp bắt đầu sau hàng cuối 120 px.
- Trang đặt tiêu đề trang tại `y = -600`, khối đầu tại `y = -300`, hàng đầu tại `y = 0`.
- Biến thể đặt ngay sau board gốc (ví dụ `1b` sau `1`).
- Ghi chú dán (sticky) đặt ngay dưới board nó nói; ghi chú xong việc thì xoá, nội dung đáng giữ chuyển vào tài liệu pattern.

**Trước khi thêm hoặc gộp board**: kiểm lại link (`href="….dc.html"`) không trỏ vào board đã xoá, và cập nhật tài liệu pattern của khối đó.

## Trạng thái

| Phần | Trạng thái | Tài liệu |
|---|---|---|
| Foundations, tokens, components, states, guidelines | Chốt | [design-system.md](design-system.md) |
| **A** Onboarding + tài khoản | **Chốt** 2026-10-21, sửa luồng 2026-10-23 | [patterns/A-onboarding-auth.md](patterns/A-onboarding-auth.md) |
| **B** Tổng quan | **Chốt** 2026-10-21 | [patterns/B-overview.md](patterns/B-overview.md) |
| **C** Giao dịch | **Chốt** 2026-10-21 | [patterns/C-transactions.md](patterns/C-transactions.md) |
| **D** Ví | **Chốt** 2026-10-21 | [patterns/D-wallets.md](patterns/D-wallets.md) |
| **E** Danh mục | **Chốt** 2026-10-21 | [patterns/E-categories.md](patterns/E-categories.md) |
| **F** Báo cáo | **Chốt** 2026-10-21 | [patterns/F-reports.md](patterns/F-reports.md) |
| **G** Cá nhân và cài đặt | **Chốt** 2026-10-21 | [patterns/G-profile-settings.md](patterns/G-profile-settings.md) |
| **H** Đồng bộ | **Chốt** 2026-10-22 | [patterns/H-sync.md](patterns/H-sync.md) |

### Phase 3 (các khối nằm theo khu vực ở trang 06–12 của canvas, chốt 2026-11-03; I đã code 2026-11-04)

| Phần | Trạng thái | Tài liệu |
|---|---|---|
| **I** Mục tiêu | **Chốt** 2026-11-03, **đã code** (`MOB-P3-E01`) | [patterns/I-goals.md](patterns/I-goals.md) |
| **K** Vay và nợ | **Chốt** 2026-11-03, **đã code** (`MOB-P3-007`, `MOB-P3-E02`) | [patterns/K-loans-debts.md](patterns/K-loans-debts.md) |
| **L** Định kỳ và hóa đơn | **Chốt** 2026-11-03, **đã code** (`MOB-P3-001`) | [patterns/L-recurring-bills.md](patterns/L-recurring-bills.md) |
| **M** Ví, hoàn tiền, trả góp | **Chốt** 2026-11-03; màn 1 (khớp số dư) **đã code** (`MOB-P3-005`), màn 2–4 (hoàn tiền) **đã code** (`MOB-P3-008`), màn 5–7 (trả góp) **đã code** (`MOB-P3-009`) | [patterns/M-wallet-refund-installment.md](patterns/M-wallet-refund-installment.md) |
| **N** Dự báo, soát tháng, ngân sách, nhắc | **Chốt** 2026-11-03; màn 1–2 (dự báo số dư) **đã code** (`MOB-P3-E04`), màn 3 (soát tháng) **đã code** (`MOB-P3-002`), màn 4 (ngưỡng ngân sách) **đã code** (`MOB-P3-003`), màn 5–6 (Thông báo, chọn giờ nhắc) **đã code** (`MOB-P3-006`) | [patterns/N-forecast-alerts.md](patterns/N-forecast-alerts.md) |
| **O** Cá nhân và dữ liệu | **Chốt** 2026-11-03; màn 3 (Xuất dữ liệu) **đã code** (`MOB-P3-010`), màn 1–2 (lưới Cá nhân, Thu nhập và kỳ tính) và 4–8 (Nhập giao dịch) **đã code** (`MOB-P3-010`, `MOB-P3-011`) | [patterns/O-profile-data.md](patterns/O-profile-data.md) |
| **A3** Onboarding ba câu | **Chốt** 2026-11-03, làm lại 2026-11-19 (Hoàn tất, sheet ngân sách, thu nhập theo khoảng) | [patterns/A3-onboarding-three-questions.md](patterns/A3-onboarding-three-questions.md) |

Cùng đợt (2026-11-03), canvas được sửa cho khớp app đang chạy (theo golden): mật khẩu 8 ký tự (AuRegister, AuReset), chip "Xem tổng theo VND" (BMulti), dòng "Xem bản soát tháng" (RepMonth), các dòng Định kỳ / Hóa đơn / Lịch và bỏ "Định dạng ngày" (MeHome), "Xuất dữ liệu" (MeProfile), các dòng Thông báo (MeNotify), "Số trả tối thiểu" và nhãn "Loại ví" (WCredit, WAddCredit). Trang 05 có thêm hàng **P2 · Đã có trong app, chưa từng vẽ** (`Cur*.dc.html`, `RevMonth.dc.html`): Ngân sách, Lịch, Hộp thư, Soát tháng, Định kỳ và Hóa đơn bản đang chạy, vẽ lại đúng app để làm mốc.

Dọn trùng (2026-11-17): onboarding A3 (ObGoals3, ObIncome, ObSaving, ObBudgetSuggest, DailyLogAsk) chuyển lên hàng A1 trang 05, thay cho ObGoals, ObNeeds, ObBudget (xoá); luồng nối lại AuVerify/ObAccount → ObGoals3 → ObIncome → ObSaving → ObBudgetSuggest → ObSetup. Quy tắc từ nay: màn đổi thì sửa tại chỗ hoặc thay bản cũ, không để hai bản song song. Sáu cặp bản cũ/bản Phase 3 đã gộp cùng ngày, bản Phase 3 thay nội dung bản cũ và giữ vị trí, tiêu đề, link của bản cũ: BNewMonth, MeHome, MeNotify, RepMonth, TxDetail, WCredit (các bản `...3` đã xoá, mọi link `...3` trỏ về tên gốc; RepMonth cao 1640 và MeHome cao 1694 nên dời tiêu đề nhóm G và hàng H xuống cho khỏi đè).

Đợt MOB-P6-001 (2026-11-17): canvas sửa cho khớp app sau test tay. Sửa tại chỗ: TxExpense (nhãn "Danh mục" trên hàng chip), TxSearch (ô tìm "Tìm giao dịch hoặc chức năng"), DailyLogAsk và NotifyTime (copy mới), TxNoResult và RepEmpty (hình empty state mới: trang giấy nổi, đồng xu, đốm sáng, chuyển động 3 vòng rồi dừng). Hàng mới cuối trang 05, tiêu đề "MOB-P6-001": TxExpenseIncome (ghi thu: Lương/Thưởng/Quà tặng, không có Cửa hàng, ô Ngày hiện 20/11), TxTagsEmpty, TxSearchQuick và TxSearchFeature (tìm cả chức năng), CatSwipe (vuốt trái Ẩn/Xoá), MePinSetup (đặt PIN từ Cài đặt, không có "Để sau"), WListHidden (Ví khi ẩn số dư, có nút mắt). Chưa có board: Splash (nền sáng, chữ Sora), đổi mật khẩu (nút mắt), bàn phím số chỉ hiện khi nhập số.

### Phase 4 (các khối nằm theo khu vực ở trang 06–12 của canvas, chốt 2026-11-06)

| Phần | Trạng thái | Tài liệu |
|---|---|---|
| **P** Đầu tư | **Chốt** 2026-11-06, đã code P.1–P.12 (`MOB-P4-E01`) | [patterns/P-investments.md](patterns/P-investments.md) |
| **Q** Tài sản ròng theo thời gian | **Chốt** 2026-11-06, đã code Q.1 (`MOB-P4-E02`) | [patterns/P-investments.md](patterns/P-investments.md) |

### Phase 5 (các khối nằm theo khu vực ở trang 06–12 của canvas, chốt 2026-11-11)

| Phần | Trạng thái | Tài liệu |
|---|---|---|
| **R** Gợi ý danh mục | **Chốt** 2026-11-11 | [patterns/R-suggestions-insights.md](patterns/R-suggestions-insights.md) |
| **S** Đáng chú ý và dự báo chi | **Chốt** 2026-11-11 | [patterns/R-suggestions-insights.md](patterns/R-suggestions-insights.md) |
| **T** Ngày dự kiến đạt mục tiêu | **Chốt** 2026-11-11 | [patterns/R-suggestions-insights.md](patterns/R-suggestions-insights.md) |
| **U** Gợi ý tự động | **Chốt** 2026-11-11 | [patterns/R-suggestions-insights.md](patterns/R-suggestions-insights.md) |

Chủ dự án bỏ what-if ("Thử bớt chi") và nút "Không đúng" (2026-11-11).

## Tiến độ code (Flutter)

Thứ tự đã chốt: nền tảng → B → C → D → E → F → G → A → H. Mỗi nhóm một nhánh + một PR vào `develop`; API nhỏ mà màn cần làm luôn trong PR đó, module lớn (ngân sách, thông báo, chế độ khách, deep link email) để trạng thái trống/ẩn.

| Nhóm | Trạng thái | Ghi chú |
|---|---|---|
| Nền tảng (`DS-P2-002`) | Xong | Token → Dart, theme, Inter, Lucide, component trong `lib/core/widgets/`, khung 4 tab + nút +, gallery `/debug/gallery`, golden light/dark |
| B Tổng quan | Xong | 8 trạng thái, `User.displayName`, net-worth bỏ ví đã ẩn, ẩn số dư chỉ ẩn số dư. `MOB-P6-005` (2026-11-20): làm lại theo PA 3 (board `BHome`): thẻ Tài sản ròng có Có/Nợ, lưới ô Tháng / Sắp phải trả / Thẻ / Mục tiêu / Đầu tư; tài sản ròng tính thêm khoản vay. Board B1–B5, B7, S.1 vẽ lại theo PA 3 (đối chiếu golden bằng `design_compare` nhóm `B`, `S`) |
| C Giao dịch | Xong | API lọc nhiều ví/danh mục/nhãn, tìm cửa hàng, `summary`; giờ giao dịch `BE-P2-E09` / `MOB-P2-E09` |
| D Ví | Xong | D1: danh sách, sắp xếp (`PUT /financial-accounts/order`), chi tiết ví (Vào/Ra tính cả chuyển ví qua `summary.transferIn/OutMinor`), chi tiết thẻ, ví đã ẩn. D2: thêm/sửa ví và thẻ, popup ngày, cờ `hasTransactions` khoá loại/tiền tệ, ẩn có Hoàn tác |
| E Danh mục | Xong | E1: danh sách Chi · Thu, mở/thu nhớ trên máy, danh mục đã ẩn; API bảng 20 màu, 36 icon, `kind` khi tạo, hai cấp, đổi icon mặc định một lần. E2: thêm/sửa, sheet Thuộc/Biểu tượng, ẩn có Hoàn tác, popup xoá + `GET /categories/{id}/usage` |
| F Báo cáo | Xong (F1 + F2) | F1: kỳ Tuần/Tháng/Năm/Tuỳ chọn, thẻ tổng (so kỳ trước, trung bình/ngày, còn lại), xu hướng 8 tuần/6 tháng/các năm (`GET /reports/trend`), phân tích Chi · Thu · Ví, trạng thái trống; khối ngân sách tháng từ `BE-P2-E02` / `MOB-P2-E02`. F2: chi tiết danh mục (kể cả "Khác") với "Giao dịch lớn nhất" (`sort=amountDesc`, `currency` trên `GET /transactions`) và "Xem cả N" mở danh sách đã lọc; popup chọn khoảng ngày (chip nhanh, lịch, tối đa 3660 ngày) |
| G Cá nhân/Cài đặt | Xong (G1 + G2) | G1: Cá nhân (thẻ hồ sơ, 3 nhóm, đăng xuất có hỏi), Hồ sơ (tên hiển thị), Giao diện, Bảo mật (đổi PIN, đổi mật khẩu `POST /auth/change-password`), Phiên đăng nhập. Chọn tiền tệ/tháng/ngôn ngữ/múi giờ lưu ngay. Bỏ dòng "Định dạng ngày" (owner 2026-10-23). Ngân sách, Mục tiêu, Thông báo, Nhãn, đổi email: toast "Sắp có". G2: Nhãn (tìm, tạo, đổi tên, xoá, số giao dịch; chạm mở giao dịch đã lọc), Góp ý gửi thật (`POST /feedback`, chưa có ảnh) + màn cảm ơn, FAQ có tìm kiếm, Thông báo (chỉ "Máy mới đăng nhập" chạy, còn lại "Sắp có") |
| A Onboarding/tài khoản | Xong (A1 + A2a + A2b) | A1: Đăng nhập một màn, Tạo tài khoản (danh sách điều kiện, đồng ý điều khoản, `termsAccepted` + migration), Xác nhận email (nút "Xong"), Quên mật khẩu, Mật khẩu mới (chờ deep link), Đặt PIN → Nhập lại → Face ID đều "Để sau" được, màn Mở khoá mới. PIN không còn bắt buộc: không PIN thì app không khoá, Bảo mật có "Đặt mã PIN". Google/Apple: nút báo "Sắp có". A2a: Welcome (một lần), Tạo tài khoản Freeva (Google/Apple "Sắp có", email), Mục tiêu (tối đa 2), Thói quen, Ngân sách tháng (tạo ngân sách thật qua `BE-P2-E02`, không được thì giữ số trên máy); câu trả lời lưu ở backend (`PATCH /profile/onboarding`); bỏ màn giới thiệu cũ trong app. A2b: Thiết lập tài chính (mỗi loại một ví, form thêm ví của nhóm D, chạy được khi chưa mở khoá), checklist "Bắt đầu nào" trên Tổng quan (tự tính từ dữ liệu thật; hết khi đã có ví và khoản đầu tiên, dòng PIN chỉ hiện khi chưa có PIN), "Chào {tên}" trên màn Mở khoá (tên lưu cùng phiên trên máy). Mục tiêu chỉ đổi thứ tự khối ở "Quản lý khoản nợ"; 5 mục tiêu còn lại chưa có khối thiết kế. `DS-P2-004` done 2026-10-29. Chưa làm: deep link, Google/Apple thật |
| H Đồng bộ | Xong (H1 + H2) | H1: banner trên Giao dịch (vàng khi cần xem, trung tính khi chỉ chờ gửi), chip "Cần xem lại" / icon đồng hồ trên dòng, màn Đồng bộ (`/sync`: thẻ trạng thái chưa có mạng / chưa gửi được / đang gửi / đã đồng bộ hết / cần cập nhật, mục cần xem với lý do và Thử lại · Bỏ, mục chờ gửi với ×, giờ lần cuối), popup "Bỏ thay đổi này?". Tiến độ không có số từng mục (một lô một lần gọi). H2: màn Chọn bản giữ lại (so hai bản, chọn sẵn bản đã lưu; giữ bản máy này = gửi lại với `version` mới của server), sheet "Có thể bạn đã ghi rồi" (hiện ở màn gốc của tab, Giữ cả hai / Xoá bản vừa ghi có Hoàn tác). Từ `MOB-P2-018`: nút "Cập nhật" (mở cửa hàng; iOS ẩn tới khi có App Store id) và "Sửa" cho thay đổi lỗi do dữ liệu. |
| I Mục tiêu (Phase 3) | Xong | `MOB-P3-E01`: danh sách và trạng thái trống, tạo/sửa (thẻ "Cần góp" tính trên máy), chi tiết + lịch sử (`GET /goals/{id}/entries`), sheet góp/rút, khối Mục tiêu trên Tổng quan, ô Mục tiêu ở Cá nhân. Golden sáng/tối + 1.3×, đối chiếu board bằng `design_compare` nhóm `I`. Khác board: lịch sử chưa có tên ví, dòng sửa số không có số mới |
| K Vay và nợ (Phase 3) | Xong | `MOB-P3-007` + `MOB-P3-E02`: Người quen (trống, danh sách, ghi khoản mượn, chi tiết + lịch sử, sheet ghi tiền nhận lại/đã trả), Khoản vay (danh sách, thêm/sửa, chi tiết với kỳ tới, cách tính, lịch trả, sheet ghi lần trả), dòng Vay và nợ ở Cá nhân. Golden sáng/tối + 1.3×, đối chiếu board bằng `design_compare` nhóm `K`. Khác board: màu avatar theo tên, ghi trả khoản vay luôn hôm nay |
| L Định kỳ và hóa đơn (Phase 3) | Xong | `MOB-P3-001`: danh sách (thẻ Cần trả, nhóm Cần trả / Ghi tự động), thêm/sửa với nhóm radio cách ghi, sheet "Đã trả" (số thật, ví, ngày, gắn khoản chi có sẵn). Golden sáng/tối + 1.3×, đối chiếu board bằng `design_compare` nhóm `L`. Khác board: Thu/Chuyển không chọn được "Hỏi trước khi ghi" (API), loại và cách ghi của khoản đã tạo chỉ đọc (API), tiêu đề sheet giữ nguyên hoa/thường của tên |
| M Hoàn tiền (Phase 3) | Xong | `MOB-P3-008`: card "Ghi hoàn tiền" trong chi tiết khoản chi, sheet ghi hoàn tiền, popup xoá khoản chi có hoàn tiền; dòng và chi tiết giao dịch hoàn tiền. "Đã hoàn" lấy từ `refundedMinor` của API. Golden sáng/tối + 1.3×, đối chiếu board bằng `design_compare` nhóm `M`. Khác board: sheet và popup nằm trên danh sách giao dịch (board vẽ trên chi tiết thẻ có trả góp), chưa có hàng "Chuyển thành trả góp" (`MOB-P3-009`), dòng phụ khoản chi chỉ giữ phần đầu để "đã hoàn …" vừa một dòng
| M Trả góp thẻ (Phase 3) | Xong | `MOB-P3-009`: hàng "Chuyển thành trả góp" trong chi tiết khoản chi trên thẻ, màn tạo lịch (số kỳ, mỗi kỳ, kỳ đầu, xem trước từ API), lịch trả góp và kết thúc sớm, thẻ "Phải trả kỳ này" + nhóm TRẢ GÓP trên chi tiết thẻ. Golden sáng/tối + 1.3×, đối chiếu board bằng `design_compare` nhóm `M`. Khác board: icon theo danh mục khoản chi, màn hẹp xếp chồng hai ô, popup xác nhận kết thúc (board chưa vẽ) |
| A3 Onboarding ba câu (Phase 3) | Xong | `MOB-P3-012`: ba câu (mục tiêu sử dụng, thu nhập, mục tiêu tiết kiệm), gợi ý ngân sách có/không mục tiêu, sheet mời bật nhắc ghi chi trên Tổng quan, dòng Thu nhập ở Cá nhân. Số cần để dành từ `POST /goals/preview`. Golden sáng/tối, test 320 pt chữ 1.3×, đối chiếu board bằng `design_compare` nhóm `A`. Khác board: màn thu nhập có bàn phím số, thanh để dành dùng token `data.saving` (#2F9E76 thay #3FA57E), màn hẹp xếp chồng hai ô |
| A3 Onboarding làm lại (Phase 6) | Xong | `MOB-P6-004` / `BE-P6-002` (2026-11-19): sáu mục tiêu chọn nhiều, thu nhập theo khoảng (`declaredIncome`, Cá nhân chọn khoảng), mục tiêu tài chính thêm Nghỉ hưu / Con cái / Kinh doanh / Sức khỏe và tên cho "Khác", màn Hoàn tất (hình vẽ bằng `CustomPainter`), bỏ ví / PIN / gợi ý ngân sách khỏi onboarding, sheet Đặt ngân sách lần đầu vào Tổng quan, checklist "Thêm ví đầu tiên". Golden sáng/tối, đối chiếu board bằng `design_compare` nhóm `A`. Icon chip Nghỉ hưu / Con cái / Khác trên canvas đổi theo icon app (ghế, em bé, ngôi sao) |

### Rà soát độ khớp UI (`DS-P2-006`, 2026-10-26)

Product owner build app và thấy màn không giống canvas. Nguyên nhân: code viết theo bảng chữ trong `patterns/*.md` thay vì số đo trong từng board `.dc.html`, và golden chỉ so app với chính nó. Đã rà 76 board, sửa token, ~35 widget chung và mọi màn A–H; icon Lucide dựng lại nét 1.75 như canvas (`apps/mobile/tool/lucide_stroke`).

Quyết định của owner trong đợt này: icon nét 1.75; trang chính lần đầu theo board ObHome (không tìm/chuông/nút nhanh); "Hóa đơn" dùng icon điện (seed + migration); dòng Nhãn có mũi tên, chạm mở sheet Xem giao dịch / Đổi tên / Xoá. Đi kèm: `GET /profile` trả `goals` để thẻ tín dụng lên đầu khi mục tiêu là quản lý nợ; Bảo mật có công tắc PIN; Hồ sơ có nút đổi ảnh và "Xoá tài khoản" (toast "Sắp có").

**Quy tắc từ nay:** code màn nào thì lấy giá trị từ board đó, rồi so ảnh: `python3 apps/mobile/tool/design_compare/render.py docs/brand/canvas <out>` và `pairs.py <out> apps/mobile` (design bên trái, golden bên phải), xem từng cặp trước khi báo xong.

Còn lệch có chủ đích hoặc chưa làm: ô thả khi kéo sắp xếp ví, icon "Thể thao" (Lucide không có tạ nằm ngang), chip "Đã xác nhận {email}" ở Mật khẩu mới (chờ deep link).

## Việc thiết kế còn lại

Tám nhóm A–H, bảy nhóm Phase 3, nhóm P, Q của Phase 4 và nhóm R, S, T, U của Phase 5 đã chốt. Còn:

- **Popup xoá tài khoản** (nhóm G, G · 12 và 12b): đã vẽ và làm ở `MOB-P2-019`. Thiếu biến thể tài khoản chỉ đăng nhập OAuth (chờ Google/Apple trên mobile).
- **Khoản bạn đi mượn** (nhóm K): chi tiết và sheet trả giống khoản cho mượn, chỉ đổi chữ; chưa vẽ riêng.
- **Hộp thư thông báo** vẽ lại 2026-11-04 (N.7, N.8): thay bản đang chạy; chưa code.

## Cách làm đã thống nhất với product owner

1. Mỗi nhóm một (hoặc hai) hàng artboard 390×844 trên trang **05 · Patterns** của canvas, nối link để bấm Play đi được hết luồng.
2. Làm xong một nhóm thì dừng cho product owner duyệt; chốt xong mới ghi vào `docs/brand/patterns/{nhóm}.md`, cập nhật file này và bản sao `canvas/`, rồi commit.
3. Chưa viết code Flutter cho tới khi product owner yêu cầu (`DS-P2-002`, `DS-P2-003`, `DS-P2-004`).

## Phản hồi đã nhận (áp cho mọi nhóm)

- **Chữ ngắn, cô đọng.** Tiêu đề ngắn, tối đa một dòng phụ. Giọng ấm nhưng không màu mè.
- **Không đưa chi tiết kỹ thuật lên UI** (độ dài mã, điều kiện hệ thống, nhãn bước kỹ thuật). Ngoại lệ: điều kiện mật khẩu hiện thành danh sách tự tick khi tạo/đặt lại mật khẩu (2026-10-23).
- **Tạo tài khoản trước khi hỏi cá nhân hoá** (2026-10-23): câu trả lời cần chỗ lưu; bước bảo mật (xác nhận email, PIN, Face ID) luôn có "Để sau" và nút đi tiếp rõ ràng. PIN luôn nhập lại một lần.
- **Không lạm dụng logo**; logo chỉ ở splash và app icon.
- **Không bắt người dùng nhập tiền sớm.** Hỏi điều dễ trước, việc tốn công sau và cho bỏ qua.
- **Mỗi màn không giống Tổng quan:** dùng đúng loại màn trong spec (danh sách, nhập liệu, chi tiết, cài đặt).
- Ưa: nền sáng, thẻ trắng bo lớn, bottom nav viên thuốc trắng có nút + ở giữa, thẻ số dư lớp màu mờ (chỉ một chỗ), minh hoạ nét vẽ tay, thẻ chọn nền xanh nhạt có dấu tích.
- Không ưa: rập khuôn, nhiều gradient, nhiều chữ giải thích, thiếu điểm nhấn.
- **Bottom nav chỉ ở màn gốc của tab**; vào màn tiếp theo thì ẩn.
- **Chọn ngày trong tháng dùng popup**, không dùng sheet. Thẻ chọn trong form: icon và chữ một dòng.
- **Chữ gợi ý ngắn, rõ, không khô** (ví dụ "Nhập số gần đúng, có thể sửa lại sau.").
- **Trạng thái phải nhìn ra được** (ví dụ mở/thu danh mục con có nút riêng). Không gắn nhãn mà người dùng phải đoán nghĩa ("Của bạn").
- **Bảng chọn màu:** nhiều lựa chọn nhưng không na ná nhau; kiểm bằng ΔE2000.
- **Báo cáo phải đủ ý người dùng cần** (trung bình/ngày, ngân sách, xu hướng) dù API chưa có; vẽ ra và ghi phụ thuộc.
- **Hồ sơ chỉ là thông tin về bạn**; tuỳ chọn của app nằm ở Cá nhân → Ứng dụng. Thiếu API thì vẽ và ghi phụ thuộc.
- **Luồng phụ (góp ý…) không được sơ sài:** có loại, chủ đề, đính kèm, màn cảm ơn.
- **Không bỏ phần UI đã duyệt chỉ vì tính năng chưa có code** (ví dụ chuông thông báo ở Tổng quan).
- **Ẩn số dư chỉ ẩn số dư**, không ẩn thu/chi hay số tiền giao dịch.
- **Đồng bộ chạy ngầm, không làm mất dữ liệu:** chỉ hiện khi có việc cần người dùng; luôn nói rõ thay đổi vẫn nằm trên máy.
- **Màu giữ như spec.** Đã thử ba mức tăng màu (icon danh mục hai tông → nền nhuộm xanh → khối màu đậm đầu màn); product owner chọn giữ nguyên. Không đề xuất lại nếu chưa được hỏi.
- **Không viết chữ kiểu "Freeva làm…, bạn…"** (2026-11-03): nghe như máy giải thích. Dùng ví dụ thực tế ("Hợp với tiền điện, nước") hoặc nói kết quả ("Giao dịch đã có sẽ được bỏ qua").
- **Nhãn phải đúng cho mọi trường hợp dùng** (2026-11-03): ví dụ "Hỏi trước khi ghi" thay "Nhắc tôi trả" vì định kỳ có cả khoản thu.
- **Sheet và popup nằm trên màn thật**, không trên khung trống; số liệu mẫu phải khớp giữa các màn liên quan.
- **Không vẽ màn trùng bố cục chỉ để đổi số**; ghi biến thể bằng ghi chú cạnh board (2026-11-03).
- **Insight phải trực quan** (2026-11-11): mỗi điều đáng chú ý có hình nhỏ (thanh so sánh, thanh ngân sách), không chỉ một câu.
- **Không thêm nút "Không đúng" cho số tính từ sổ** (2026-11-11): số thật thì không cần báo sai; gợi ý danh mục sửa bằng cách chọn lại.
- **Danh sách cài đặt dài thì tách**: chỗ dùng thường xuyên thành lưới ô, cài đặt chỉnh một lần gộp vào màn con (Cá nhân, 2026-11-03).
- Product owner gửi ảnh tham chiếu thường xuyên: chỉ dùng để thiết kế, **không lưu vào repo**. Điều rút ra từ ảnh thì ghi thành chữ vào spec hoặc file pattern.

## Ghi chú kỹ thuật cho người sửa canvas

- Canvas là Artifact loại Design: file `project/canvas.json` (index, `pages`, `boards`, `order`, `notes`) và `project/*.dc.html`. Ảnh logo đã tải lên dạng asset `/_blob/…` (xem `canvas/Logo.dc.html`).
- Trang canvas (id): `f` Foundations · `t` Tokens · `c` Components · `s` States · `p` Patterns · `ob` Onboarding và tài khoản · `ov` Tổng quan, báo cáo, dự báo · `tx` Giao dịch · `wa` Ví và tài sản · `ca` Danh mục · `pl` Mục tiêu, vay nợ, định kỳ · `me` Cá nhân, dữ liệu, đồng bộ · `g` Guidelines.
- Board Phase 3 có tiêu đề dạng "I · 1. Tên màn"; màn có sheet/popup dùng nguyên nội dung màn nền bên dưới lớp tối.
- Màu trong artboard là hex theo token v2 (ink `#22283A`, canvas `#FCFDFF`, action `#3F67D1`, wash ở `.wash`).
