# Tiến độ thiết kế UI v2 — bàn giao giữa các phiên

Đọc file này trước khi tiếp tục thiết kế. Cập nhật mỗi khi chốt một nhóm.

- Spec: [design-system.md](design-system.md) · token: [`packages/design-tokens`](../../packages/design-tokens/)
- Canvas (riêng tư, của product owner): <https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>
- Bản sao nguồn canvas trong repo: [canvas/](canvas/) (`canvas.json` + mỗi artboard một `.dc.html`). Nếu canvas và repo lệch nhau: tài liệu và token trong repo thắng.
- Nhánh: `feat/DS-P2-001-design-system-v2`

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

## Tiến độ code (Flutter)

Thứ tự đã chốt: nền tảng → B → C → D → E → F → G → A → H. Mỗi nhóm một nhánh + một PR vào `develop`; API nhỏ mà màn cần làm luôn trong PR đó, module lớn (ngân sách, thông báo, chế độ khách, deep link email) để trạng thái trống/ẩn.

| Nhóm | Trạng thái | Ghi chú |
|---|---|---|
| Nền tảng (`DS-P2-002`) | Xong | Token → Dart, theme, Inter, Lucide, component trong `lib/core/widgets/`, khung 4 tab + nút +, gallery `/debug/gallery`, golden light/dark |
| B Tổng quan | Xong | 8 trạng thái, `User.displayName`, net-worth bỏ ví đã ẩn, ẩn số dư chỉ ẩn số dư |
| C Giao dịch | Xong | API lọc nhiều ví/danh mục/nhãn, tìm cửa hàng, `summary`; giờ giao dịch `BE-P2-E09` / `MOB-P2-E09` |
| D Ví | Xong | D1: danh sách, sắp xếp (`PUT /financial-accounts/order`), chi tiết ví (Vào/Ra tính cả chuyển ví qua `summary.transferIn/OutMinor`), chi tiết thẻ, ví đã ẩn. D2: thêm/sửa ví và thẻ, popup ngày, cờ `hasTransactions` khoá loại/tiền tệ, ẩn có Hoàn tác |
| E Danh mục | Xong | E1: danh sách Chi · Thu, mở/thu nhớ trên máy, danh mục đã ẩn; API bảng 20 màu, 36 icon, `kind` khi tạo, hai cấp, đổi icon mặc định một lần. E2: thêm/sửa, sheet Thuộc/Biểu tượng, ẩn có Hoàn tác, popup xoá + `GET /categories/{id}/usage` |
| F Báo cáo | Xong (F1 + F2) | F1: kỳ Tuần/Tháng/Năm/Tuỳ chọn, thẻ tổng (so kỳ trước, trung bình/ngày, còn lại), xu hướng 8 tuần/6 tháng/các năm (`GET /reports/trend`), phân tích Chi · Thu · Ví, trạng thái trống; khối ngân sách tháng từ `BE-P2-E02` / `MOB-P2-E02`. F2: chi tiết danh mục (kể cả "Khác") với "Giao dịch lớn nhất" (`sort=amountDesc`, `currency` trên `GET /transactions`) và "Xem cả N" mở danh sách đã lọc; popup chọn khoảng ngày (chip nhanh, lịch, tối đa 3660 ngày) |
| G Cá nhân/Cài đặt | Xong (G1 + G2) | G1: Cá nhân (thẻ hồ sơ, 3 nhóm, đăng xuất có hỏi), Hồ sơ (tên hiển thị), Giao diện, Bảo mật (đổi PIN, đổi mật khẩu `POST /auth/change-password`), Phiên đăng nhập. Chọn tiền tệ/tháng/ngôn ngữ/múi giờ lưu ngay. Bỏ dòng "Định dạng ngày" (owner 2026-10-23). Ngân sách, Mục tiêu, Thông báo, Nhãn, đổi email: toast "Sắp có". G2: Nhãn (tìm, tạo, đổi tên, xoá, số giao dịch; chạm mở giao dịch đã lọc), Góp ý gửi thật (`POST /feedback`, chưa có ảnh) + màn cảm ơn, FAQ có tìm kiếm, Thông báo (chỉ "Máy mới đăng nhập" chạy, còn lại "Sắp có") |
| A Onboarding/tài khoản | Xong (A1 + A2a + A2b) | A1: Đăng nhập một màn, Tạo tài khoản (danh sách điều kiện, đồng ý điều khoản, `termsAccepted` + migration), Xác nhận email (nút "Xong"), Quên mật khẩu, Mật khẩu mới (chờ deep link), Đặt PIN → Nhập lại → Face ID đều "Để sau" được, màn Mở khoá mới. PIN không còn bắt buộc: không PIN thì app không khoá, Bảo mật có "Đặt mã PIN". Google/Apple: nút báo "Sắp có". A2a: Welcome (một lần), Tạo tài khoản Freeva (Google/Apple "Sắp có", email), Mục tiêu (tối đa 2), Thói quen, Ngân sách tháng (tạo ngân sách thật qua `BE-P2-E02`, không được thì giữ số trên máy); câu trả lời lưu ở backend (`PATCH /profile/onboarding`); bỏ màn giới thiệu cũ trong app. A2b: Thiết lập tài chính (mỗi loại một ví, form thêm ví của nhóm D, chạy được khi chưa mở khoá), checklist "Bắt đầu nào" trên Tổng quan (tự tính từ dữ liệu thật; hết khi đã có ví và khoản đầu tiên, dòng PIN chỉ hiện khi chưa có PIN), "Chào {tên}" trên màn Mở khoá (tên lưu cùng phiên trên máy). Mục tiêu chỉ đổi thứ tự khối ở "Quản lý khoản nợ"; 5 mục tiêu còn lại chưa có khối thiết kế. `DS-P2-004` done 2026-10-29. Chưa làm: xác nhận lại email trong Cá nhân, deep link, Google/Apple thật |
| H Đồng bộ | Xong (H1 + H2) | H1: banner trên Giao dịch (vàng khi cần xem, trung tính khi chỉ chờ gửi), chip "Cần xem lại" / icon đồng hồ trên dòng, màn Đồng bộ (`/sync`: thẻ trạng thái chưa có mạng / chưa gửi được / đang gửi / đã đồng bộ hết / cần cập nhật, mục cần xem với lý do và Thử lại · Bỏ, mục chờ gửi với ×, giờ lần cuối), popup "Bỏ thay đổi này?". Tiến độ không có số từng mục (một lô một lần gọi); nút "Cập nhật" và "Sửa" để sau. H2: màn Chọn bản giữ lại (so hai bản, chọn sẵn bản đã lưu; giữ bản máy này = gửi lại với `version` mới của server), sheet "Có thể bạn đã ghi rồi" (hiện ở màn gốc của tab, Giữ cả hai / Xoá bản vừa ghi có Hoàn tác). Chưa làm: nút "Cập nhật", nút "Sửa" |

### Rà soát độ khớp UI (`DS-P2-006`, 2026-10-26)

Product owner build app và thấy màn không giống canvas. Nguyên nhân: code viết theo bảng chữ trong `patterns/*.md` thay vì số đo trong từng board `.dc.html`, và golden chỉ so app với chính nó. Đã rà 76 board, sửa token, ~35 widget chung và mọi màn A–H; icon Lucide dựng lại nét 1.75 như canvas (`apps/mobile/tool/lucide_stroke`).

Quyết định của owner trong đợt này: icon nét 1.75; trang chính lần đầu theo board ObHome (không tìm/chuông/nút nhanh); "Hóa đơn" dùng icon điện (seed + migration); dòng Nhãn có mũi tên, chạm mở sheet Xem giao dịch / Đổi tên / Xoá. Đi kèm: `GET /profile` trả `goals` để thẻ tín dụng lên đầu khi mục tiêu là quản lý nợ; Bảo mật có công tắc PIN; Hồ sơ có nút đổi ảnh và "Xoá tài khoản" (toast "Sắp có").

**Quy tắc từ nay:** code màn nào thì lấy giá trị từ board đó, rồi so ảnh: `python3 apps/mobile/tool/design_compare/render.py docs/brand/canvas <out>` và `pairs.py <out> apps/mobile` (design bên trái, golden bên phải), xem từng cặp trước khi báo xong.

Còn lệch có chủ đích hoặc chưa làm: ô thả khi kéo sắp xếp ví, icon "Thể thao" (Lucide không có tạ nằm ngang), nhãn "Email · đã xác nhận" (API chưa có cờ xác nhận), chip "Đã xác nhận {email}" ở Mật khẩu mới (chờ deep link).

## Việc thiết kế còn lại

Tám nhóm A–H đã chốt. Còn:

- **Popup xoá tài khoản** và dòng **Xuất dữ liệu** (nhóm G): đã làm bằng hộp xác nhận chung ở `MOB-P2-011`; chưa vẽ trên board.

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
- Product owner gửi ảnh tham chiếu thường xuyên: chỉ dùng để thiết kế, **không lưu vào repo**. Điều rút ra từ ảnh thì ghi thành chữ vào spec hoặc file pattern.

## Ghi chú kỹ thuật cho người sửa canvas

- Canvas là Artifact loại Design: file `project/canvas.json` (index, `pages`, `boards`, `order`, `notes`) và `project/*.dc.html`. Ảnh logo đã tải lên dạng asset `/_blob/…` (xem `canvas/Logo.dc.html`).
- Trang canvas: `f` Foundations · `t` Tokens · `c` Components · `s` States · `p` Patterns · `g` Guidelines.
- Màu trong artboard là hex theo token v2 (ink `#22283A`, canvas `#FCFDFF`, action `#3F67D1`, wash ở `.wash`).
