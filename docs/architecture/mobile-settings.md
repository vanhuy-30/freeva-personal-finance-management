# Cài đặt và trợ giúp — MOB-P1-007

Home có mục **Cài đặt** (`/settings`, qua AuthGate). Không đổi API. Ngôn ngữ, tiền tệ, múi giờ và ngày đầu kỳ vẫn thuộc hồ sơ [MOB-P1-002](mobile-profile.md).

## Hành vi

- Theme: sáng (mặc định), tối, hoặc theo hệ thống. Lưu trên thiết bị, key secure storage `freeva.preferences.v1`, tách khỏi vault phiên. Đăng xuất không xóa theme. `main` tải xong preference rồi mới `runApp`.
- Một dòng dẫn tới `/profile` và hiện ngôn ngữ đã lưu. Không sửa locale tại màn cài đặt.
- Sinh trắc bật/tắt cờ trong bản ghi PIN hiện có. Bật cần máy có sinh trắc và xác thực thành công; nếu xác thực thất bại thì cờ không đổi. Tắt không cần xác thực. Chưa có PIN thì báo tạo PIN ở màn khóa. `biometricAvailable()` của màn khóa giữ nguyên nghĩa. Không mở Settings hệ thống. Quyền thông báo chỉ xin khi có phiên đăng nhập khác, thuộc [MOB-P1-009](mobile-privacy.md).
- Onboarding ba bước, một lần mỗi cài đặt, chỉ khi phiên đã mở khóa. Bỏ qua và hoàn tất đều ghi cờ và phát `onboarding_completed` một lần. `onboarding_started` một lần khi mở bước đầu. Redirect bỏ qua `/splash`.
- FAQ tĩnh trong l10n. Phản hồi chọn góp ý hoặc lỗi, 1–2000 ký tự, sao chép trên máy. Không tải lên, không ghi nội dung vào log. Chưa có địa chỉ nhận vì [DECISIONS-OPEN #10](../project-state/DECISIONS-OPEN.md).
- Phiên bản hiển thị `0.0.1+1`, khớp `pubspec.yaml`. Điều khoản và chính sách là bản nháp `PRD-P0-002`, ghi rõ chưa có hiệu lực và pháp nhân/kênh liên hệ chưa chốt.

## Layer và quyền riêng tư

`settings/{domain,data,presentation}`. Repository, use case và ViewModel đăng ký abstract. View không gọi repository. Domain không import Flutter. ViewModel không import `material.dart`.

Bản ghi preference có `theme` và `onboardingCompleted`. Các cờ ẩn số dư và cảnh báo phiên thuộc [MOB-P1-009](mobile-privacy.md); bản ghi cũ thiếu những khóa đó vẫn đọc được. Chuỗi phản hồi do use case ghép từ phiên bản, loại và nội dung đã trim; page mới đưa vào clipboard. Analytics chỉ nhận hai event onboarding đã có trong catalog.

## Giới hạn

Không help center, ticket hay SLA (Phase 7). Không endpoint phản hồi. Quyền thông báo không xin lúc mở app; chỉ xin khi có phiên đăng nhập khác ([MOB-P1-009](mobile-privacy.md)). Chưa native build hoặc E2E staging.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 108 Flutter tests pass (14 tests mới).

## DS-P2-003 nhóm G (G1)

Thiết kế: [G-profile-settings.md](../brand/patterns/G-profile-settings.md).

- **Cá nhân** (`/me`, tab gốc): thẻ hồ sơ (avatar chữ cái, tên, email che; email lấy từ két máy, API hồ sơ không trả email), nhóm Thiết lập tài chính / Ứng dụng / Hỗ trợ. Tiền tệ, Tháng tính từ, Ngôn ngữ, Múi giờ mở sheet chọn rồi `PUT /profile` ngay, lỗi thì trả giá trị cũ và báo. Ẩn số dư là công tắc. Ngân sách, Mục tiêu, Thông báo, Nhãn: toast "Sắp có". Đăng xuất hỏi lại.
- **Hồ sơ** (`/profile`): tên hiển thị (gửi trong `PUT /profile`, để trống là xoá); email có "Đổi" nhưng chưa làm (cần xác nhận qua thư).
- **Bảo mật** (`/me/security`): PIN luôn bật; sinh trắc là công tắc; **Đổi mã PIN** nhập PIN cũ (tính như một lần mở khoá, sai 5 lần thì xoá máy), PIN mới, nhập lại; **Đổi mật khẩu** gọi `POST /auth/change-password` (403 là sai mật khẩu hiện tại; máy này giữ phiên, máy khác bị đăng xuất).
- **Phiên đăng nhập** (`/me/sessions`): Máy này + chip, phiên khác + Thu hồi (hỏi lại), "Đăng xuất mọi máy khác" (thu hồi từng phiên khác, không đụng phiên hiện tại).
- Chưa có avatar ảnh, xoá tài khoản, đổi email.

### G2

- **Nhãn** (`/me/tags`): tìm, tạo, đổi tên, xoá (hỏi lại) qua menu ⋯ mỗi dòng; số giao dịch lấy từ `GET /tags`. Chạm dòng đặt bộ lọc `tagIds` (mọi thời gian) rồi mở `/transactions`.
- **Góp ý** (`/help/feedback`): loại (Lỗi/Ý tưởng/Lời khen), chủ đề, nội dung (đếm ký tự), "Trả lời tôi qua email", gửi `POST /feedback` ([feedback.md](feedback.md)); xong hiện màn cảm ơn. Thay cho luồng sao chép Phase 1. Chưa có ảnh chụp màn hình. Lỗi mạng/quá giới hạn báo bằng toast, nội dung vẫn còn.
- **FAQ**: ô tìm, một câu mở một lúc, thẻ "Gửi góp ý cho Freeva".
- **Thông báo** (`/me/notifications`): ngân sách, định kỳ và thẻ qua API (`BE-P2-E05`, `BE-P2-E07`); "Máy mới đăng nhập" vẫn trên máy (`sessionAlertsEnabled`); giờ yên theo timezone hồ sơ; mục tiêu/nợ/soát tháng/insight hiện "Sắp có". Push FCM: `BE-P2-015`.
