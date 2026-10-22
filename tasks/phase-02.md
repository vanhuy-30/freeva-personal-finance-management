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
- Status: doing
- Module: —
- Gate: post-v1
- Depends: DS-P2-002
- DoD: Tổng quan theo [B-overview.md](../docs/brand/patterns/B-overview.md) (đủ 8 trạng thái; ẩn số dư chỉ ẩn số dư); Ví theo [D-wallets.md](../docs/brand/patterns/D-wallets.md); Danh mục theo [E-categories.md](../docs/brand/patterns/E-categories.md) (màu và biểu tượng mới cần task BE riêng); Báo cáo theo [F-reports.md](../docs/brand/patterns/F-reports.md) (chuỗi xu hướng, kỳ năm cần task BE riêng; khối ngân sách theo `BE-P2-E02`); Cá nhân/Cài đặt theo [G-profile-settings.md](../docs/brand/patterns/G-profile-settings.md) (trường hồ sơ mới, đổi email/mật khẩu, liên kết, xoá tài khoản, API góp ý cần task BE riêng); Đồng bộ theo [H-sync.md](../docs/brand/patterns/H-sync.md) (giữ bản trên máy và mã lý do lỗi cần task BE riêng). Bottom nav chỉ ở màn gốc của tab. Theo thứ tự Tổng quan → Ghi giao dịch → Danh sách giao dịch → Ví → Báo cáo → Cá nhân/Cài đặt/Giới thiệu/Đăng nhập/Khoá. Chỉ đổi View và widget, không đổi ViewModel/use case. Mỗi màn một PR. Không còn hex rời hay `Icons.*` trong `lib/features`. Đo lại ghi chi < 10 giây (QA-P1-001). Chạy được ở màn 320 pt và cỡ chữ 1.3×.

### DS-P2-004 — Onboarding và tài khoản theo thiết kế nhóm A
- Status: todo
- Module: 1, 24
- Gate: post-v1
- Depends: DS-P2-002
- DoD: luồng và màn theo [A-onboarding-auth.md](../docs/brand/patterns/A-onboarding-auth.md): Welcome → Mục tiêu (tối đa 2) → Thói quen → Ngân sách (ẩn hoặc lưu tạm nếu chưa có `BE-P2-E02`) → Tạo tài khoản → Thiết lập tài chính (không bắt buộc) → Trang chính có checklist. Đăng nhập email + mật khẩu một màn. PIN không chặn đường vào app. Deep link xác nhận email / đặt lại mật khẩu và Google/Apple mobile tách task BE/MOB riêng khi làm.

### DS-P2-005 — Giao dịch theo thiết kế nhóm C
- Status: done
- Module: 4, 5
- Gate: post-v1
- Depends: DS-P2-002
- DoD: màn và luồng theo [C-transactions.md](../docs/brand/patterns/C-transactions.md): danh sách có chip lọc và tổng theo bộ lọc, tìm không dấu, sheet bộ lọc, trạng thái không kết quả, sheet chi tiết (sửa, sao chép, xoá có Hoàn tác), mục Đã xoá, ghi chi/thu với sheet danh mục và sheet nhãn, chuyển ví khác tiền tệ có tỷ giá + thời điểm. Lọc nhiều ví/danh mục, lọc nhãn, tìm theo cửa hàng và tổng theo bộ lọc tách task BE/MOB riêng khi làm.

### BE-P2-E01 / MOB-P2-E01 — Giao dịch định kỳ (module 6)
- Status: todo
- Module: 6
- Gate: post-v1
- Depends: BE-P1-005, MOB-P1-004
- DoD: chu kỳ ngày, tuần, tháng, năm và custom. Có số tiền, ví, danh mục, ngày bắt đầu, ngày kết thúc, lần chạy tới, bật/tắt. Đến hạn tạo giao dịch đúng một lần; retry và sync không nhân đôi. Tắt thì không tạo thêm. Chuyển khoản định kỳ vẫn là hai leg cân bằng. Test tháng không có ngày 31.

### BE-P2-E02 / MOB-P2-E02 — Ngân sách (module 7)
- Status: todo
- Module: 7
- Gate: v1
- Depends: BE-P1-005, BE-P1-006, MOB-P1-006
- DoD: ngân sách tổng tháng và theo danh mục, minor units. Đã chi chỉ tính expense chưa xóa; transfer và income không tính. Mức `<70%` healthy, `70–90%` warning, `>90%` critical, `>100%` over. Ngưỡng cảnh báo mặc định 70, 80, 90, 100 và user sửa được. Home hiện thanh `đã chi / hạn mức` khi có ngân sách. Test một bảng số. Gửi push thuộc `BE-P2-E05`.

### BE-P2-E03 / MOB-P2-E03 — Hóa đơn (module 8)
- Status: todo
- Module: 8
- Gate: post-v1
- Depends: BE-P2-E01
- DoD: hóa đơn một lần hoặc gắn một định kỳ. Có hạn, số cố định hoặc ước tính. Đánh dấu đã trả thì trỏ tới một giao dịch. Quá hạn không tự tạo giao dịch.

### MOB-P2-E04 / BE-P2-E04 — Lịch tài chính bản đầu (module 15)
- Status: todo
- Module: 15
- Gate: post-v1
- Depends: BE-P1-005, BE-P2-E01
- DoD: một tháng hiện giao dịch đã ghi, lần chạy định kỳ và hạn hóa đơn theo timezone hồ sơ.

### BE-P2-E05 / MOB-P2-E05 — Thông báo và giờ yên (module 17)
- Status: todo
- Module: 17
- Gate: post-v1
- Depends: BE-P2-E02
- DoD: từng loại bật tắt được: ngân sách 80% và vượt, nhắc đóng góp mục tiêu, nợ đến hạn, thẻ đến hạn, định kỳ sắp chạy, soát tháng, insight mới, cảnh báo bảo mật. Giờ yên và timezone hồ sơ được tôn trọng. Nội dung không đưa số dư đầy đủ nếu câu thông báo không cần. Chưa có module nguồn thì loại đó tắt và không gửi.

### BE-P2-E06 — Mở rộng báo cáo và search (14, 19)
- Status: todo
- Module: 14, 19
- Gate: post-v1
- Depends: BE-P1-007, BE-P1-008
- DoD: so cùng kỳ trước, savings rate = tiết kiệm / thu nhập, xu hướng thu chi cho 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm và toàn bộ. Top merchant chỉ khi `BE-P1-012` đã có merchant.

### BE-P2-E07 / MOB-P2-E07 — Vòng đời thẻ tín dụng
- Status: todo
- Module: 3
- Gate: post-v1
- Depends: BE-P1-004, BE-P1-007
- DoD: từ hạn mức và số dư suy ra dư nợ và hạn mức còn. Giữ ngày chốt và ngày đến hạn 1–28. Thêm số trả tối thiểu. Cảnh báo sắp đến hạn, dư nợ cao và sắp vượt hạn mức. Không tự trả nợ.

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
