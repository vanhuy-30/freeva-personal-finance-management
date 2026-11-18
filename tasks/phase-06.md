# Phase 6 — epic

[phase-06.md](../docs/product/phases/phase-06.md)

Điều kiện tiên quyết: DPA đối tác, chống trùng ổn, threat model RBAC. Không thuộc product v1.

### BE-P6-E01 / MOB-P6-E01 — Kết nối ngân hàng qua đối tác (module 13 API)
- Status: todo
- Module: 13
- Gate: post-v1
- Depends: BE-P5-E08, SEC-P6-E01
- DoD: đồng bộ không ghi đè giao dịch sửa tay. Mỗi dòng có nguồn. Ngắt kết nối thì thu hồi hoặc xóa token đối tác. Cờ `bank_connect` tắt thì không hiện lối kết nối. Lỗi đối tác có runbook.
- Note: 2026-11-11 bỏ phụ thuộc `BE-P5-E01` (nhập sao kê file không làm). Chống trùng dùng lại quy tắc của `BE-P3-011`.
- Note: 2026-11-18 chủ dự án chốt: tùy chọn, hoãn, chưa làm lúc này.

### BE-P6-E02 / MOB-P6-E02 — Gia đình và chia sẻ (module 16)
- Status: todo
- Module: 16
- Gate: post-v1
- Depends: SEC-P6-E01, BE-P5-E08
- DoD: ma trận quyền ghi rõ ví nào được chia sẻ. Ví không chia sẻ không xuất hiện với thành viên khác. Cờ `family`. Mời và rời nhóm có audit.
- Note: 2026-11-18 chủ dự án chốt: tùy chọn, hoãn, chưa làm lúc này.

### SEC-P6-E01 — Token đối tác, xung đột nhiều người, audit
- Status: todo
- Module: 22, 16, 13
- Gate: post-v1
- Depends: SEC-P0-001
- DoD: threat model cập nhật cho token đối tác và hai người sửa cùng một sổ. Audit gắn actor. Không log số dư trong payload đối tác.
- Note: 2026-11-18 hoãn theo `BE-P6-E01` và `BE-P6-E02` (chỉ cần khi làm một trong hai).

### SEC-P6-002 — Rà soát test sâu và vá bảo mật trước store
- Status: done
- Module: 22
- Gate: v1
- Depends: SEC-P1-001
- DoD: chạy những gì CI không chạy (integration local, thứ tự ngẫu nhiên, nhiều múi giờ, drift Prisma, audit dependency, test web-admin). Lỗi tìm được có test tái hiện. Rate limit auth đúng IP client sau proxy. Xóa và xuất toàn bộ tài khoản phải nhập lại mật khẩu (tài khoản chỉ OAuth: phiên ≤ 10 phút). Web admin có header chống clickjacking. Dependency vá trong cùng major.
- Verification: xem [security-test-phase1.md](../docs/architecture/security-test-phase1.md#đợt-rà-soát-sec-p6-002).
- Note: `POST /v1/account/export` thay `GET`; app build cũ không xuất/xóa được tài khoản cho tới khi cập nhật (staging). Render đặt `TRUST_PROXY_HOPS=1`; số hop thật cần kiểm trên staging.
- Tồn đọng (task riêng khi cần):
  - Staff dùng chung một token và web admin không có đăng nhập: audit không phân biệt người, không thu hồi riêng.
  - Rate limit 5 lần/email: người khác có thể khóa đăng nhập của một email.
  - Đăng nhập không bắt email đã xác minh: có thể đăng ký trước email của người khác.
  - Android release còn ký bằng debug key; iOS `aps-environment` = development.
  - `deepmerge-ts` 7 (Prisma 6), `glob`/`minimatch` trong tooling build của `@sentry/nextjs` cần major mới.

### MOB-P6-001 — Cài lại app đăng nhập lại từ đầu; bottom nav sát mép dưới
- Status: in progress
- Module: 22, UI shell
- Gate: v1
- DoD: xóa app rồi cài lại thì vào Welcome và phải đăng nhập lại (iOS giữ Keychain sau khi xóa app; marker trong thư mục support của app, không có marker thì xóa toàn bộ vault). Bottom nav cách mép dưới 28 như board trên máy vuốt (inset ≤ 34); máy có thanh nút hệ thống thì nằm trên các nút, cách 8.
- Note: bản cài đang có (chưa có marker) sẽ phải đăng nhập lại một lần sau khi cập nhật.
- Đợt 2 (cùng task, phản hồi test tay):
  - Bàn phím số ghi giao dịch: mở sẵn khi vào màn, hạ xuống khi chạm chỗ khác (trừ ô số tiền), chạm số tiền thì hiện lại; con trỏ chỉ hiện khi bàn phím mở.
  - Lưu khoản chi chưa có danh mục: chặn ở app, báo "Chọn danh mục cho khoản chi." và mở luôn ô chọn danh mục; thiếu số tiền thì mở bàn phím. Sửa bất kỳ trường nào thì lỗi biến mất.
  - Chọn nhãn: luôn có dòng "Tạo nhãn" (hỏi tên), kể cả khi chưa có nhãn nào; tạo xong thì ô tìm được xóa.
  - Tổng quan tải lại khi quay về từ màn được `push` (ghi chi): go_router 14 bỏ route push khỏi `uri`, dùng `topLocation`.
  - Sheet mở trên root navigator: không còn bị bottom nav đè và tràn (sheet "Nhắc ghi chi mỗi tối?").
- Đợt 3 (phản hồi test tay):
  - Sheet nhắc ghi chi: tiêu đề bỏ dấu `?`, bỏ câu phụ "Hôm nào đã ghi thì không nhắc.", nút "Bật nhắc" thành "Bật"; popup chọn giờ cũng bỏ câu đó. Board `DailyLogAsk`, `NotifyTime` và pattern A3, N sửa theo.
  - Ví của tôi khi "Ẩn số dư" đang bật: có nút mắt cạnh tổng số dư để hiện lại ngay tại màn này (cùng một cài đặt với Tổng quan).
  - Ghi thu: nhãn "Danh mục" trên hàng chip; chưa có lịch sử thì chip lấy vài danh mục đầu của loại thu (Lương, Quà tặng, Thưởng…). Ghi thu không có ô "Cửa hàng" (khoản thu đang sửa đã có cửa hàng thì vẫn hiện).
- Đợt 4 (phản hồi test tay):
  - Ghi chi không còn tự chọn danh mục của loại thu: danh mục mặc định lấy từ các danh mục gần đây nhưng chỉ loại hợp với chi (trước đây vừa ghi thu "Lương" thì Chi cũng chọn sẵn "Lương").
  - Splash làm lại cho cân: biểu tượng nhỏ lại (62% bề rộng, tối đa 260), chữ FREEVA font Sora 600 (file `assets/fonts/Sora-Variable.ttf`, OFL), tiêu đề "Your financial freedom journey" (17px, ink600), nền sáng sạch (trắng sang xanh nhạt, chỉ chút tím ở góc dưới). Thêm golden `test/goldens/splash.png`.
- Đợt 5 (phản hồi test tay):
  - Xuất dữ liệu / Nhập từ app khác báo lỗi `GetIt ... DataExportViewModel is not registered`: hai view model chỉ đăng ký theo kiểu cài đặt, nay đăng ký theo kiểu trừu tượng; thêm test quét mọi `getIt<...ViewModel>` đều đã đăng ký.
  - Đổi mật khẩu: 3 ô có nút mắt hiện/ẩn (ô PIN giữ nguyên, không có mắt).
  - Đặt mã PIN từ Cài đặt: bỏ "Để sau" (onboarding vẫn giữ); đặt xong về thẳng Bảo mật bằng `go`, không còn nằm lại màn đặt PIN.
  - Ô Ngày khi ghi thu/chi: Hôm nay / Hôm qua / Ngày mai, ngày khác hiện 20/11 (thêm năm nếu khác năm nay), không hiện "Thứ Sáu". Phần chi tiết thêm cũng theo.
  - Chuyển ví: chọn ví luôn hiện số dư dù đang "Ẩn số dư".
  - Danh mục: vuốt hàng sang trái ra "Ẩn" và "Xoá" (cả danh mục con); dùng đúng luật của màn sửa (còn danh mục con thì báo "Còn n danh mục con"; xoá vẫn hỏi chuyển giao dịch sang đâu). Widget dùng chung `SwipeActions`.
  - Tìm kiếm ở Tổng quan: tìm được cả chức năng (Ví, Danh mục, Ngân sách, Xuất dữ liệu, Đổi mật khẩu…, không dấu và theo từ khoá), có "Mở nhanh" khi chưa gõ.
  - Empty state: hình mới (trang giấy nổi, đồng xu, đốm sáng) thay chữ F, chuyển động 3 vòng rồi dừng, tắt khi giảm chuyển động; bỏ `FStrokesMark`.
- Đợt 6 (phản hồi test tay):
  - Thông báo chưa có: chỉ một câu "Bạn chưa có thông báo nào để hiển thị".
  - Phiên đăng nhập: bỏ câu "Không nhận ra phiên nào thì thu hồi ngay."; nút thành "Đăng xuất khỏi mọi thiết bị" (máy này vẫn đăng nhập).
  - Cá nhân bỏ "Múi giờ": tài khoản theo múi giờ của máy, mỗi lần tải hồ sơ app so với múi giờ máy và tự lưu nếu khác (server phải có trong danh sách). Thêm `flutter_timezone`.
  - Cá nhân bỏ "Ẩn số dư": chỉ bật/tắt bằng nút mắt ở Tổng quan (và Ví của tôi).
  - Danh mục: hàng đang mở vuốt sang phải thì đóng lại (trước đó vuốt phải không ăn).
  - Nút nhanh ở Tổng quan: "Danh mục" thành "Đầu tư" (Ghi thu · Chuyển ví · Ví của tôi · Đầu tư).
  - Cá nhân chia nhóm lại (board `MeHome`): Tài sản (Ví · Tài sản ròng · Đầu tư · Vay và nợ) và Kế hoạch (Ngân sách · Mục tiêu · Định kỳ · Lịch), mỗi nhóm một hàng 4 ô không số phụ; Gợi ý tự động sang Thiết lập; Dữ liệu và Hỗ trợ gộp một nhóm.

### BE-P6-001 / MOB-P6-002 — Quản lý phiên đăng nhập theo thiết bị
- Status: doing
- Module: 22
- Gate: v1
- Depends: MOB-P6-001
- DoD:
  - App gửi `device` khi đăng nhập: `id` (UUID tạo một lần, giữ qua lần cài lại trên iOS), `name` (tên máy, ví dụ "iPhone 15 Pro"), `platform` (`ios`/`android`), `osVersion`. Không gửi tên máy do người dùng đặt.
  - `AuthSession` thêm `deviceId`, `deviceName`, `platform`, `osVersion`, `lastUsedAt`. Đăng nhập lại cùng `deviceId` thì xoá phiên cũ của máy đó trong cùng giao dịch: mỗi máy chỉ còn một phiên.
  - `lastUsedAt` cập nhật khi phiên được dùng, tối đa một lần mỗi giờ.
  - `GET /v1/sessions` trả thêm `deviceName`, `platform`, `osVersion`, `lastUsedAt`; phiên cũ không có thông tin máy vẫn hiện.
  - Màn Phiên đăng nhập: mỗi dòng là một thiết bị (tên máy; dòng phụ "Android 14 · 3 giờ trước" theo lần dùng gần nhất, máy này "iOS 18.1 · Đăng nhập 02/10" + chip "Đang dùng"). Không có tên máy thì "Thiết bị không rõ" + ngày đăng nhập. "Thu hồi" thành "Đăng xuất".
  - OpenAPI, migration Prisma, test BE (unit + integration) và mobile.

