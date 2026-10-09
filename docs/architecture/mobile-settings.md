# Cài đặt và trợ giúp — MOB-P1-007

Home có mục **Cài đặt** (`/settings`, qua AuthGate). Không đổi API. Ngôn ngữ, tiền tệ, múi giờ và ngày đầu kỳ vẫn thuộc hồ sơ [MOB-P1-002](mobile-profile.md).

## Hành vi

- Theme: sáng (mặc định), tối, hoặc theo hệ thống. Lưu trên thiết bị, key secure storage `freeva.preferences.v1`, tách khỏi vault phiên. Đăng xuất không xóa theme. `main` tải xong preference rồi mới `runApp`.
- Một dòng dẫn tới `/profile` và hiện ngôn ngữ đã lưu. Không sửa locale tại màn cài đặt.
- Sinh trắc bật/tắt cờ trong bản ghi PIN hiện có. Bật cần máy có sinh trắc và xác thực thành công; nếu xác thực thất bại thì cờ không đổi. Tắt không cần xác thực. Chưa có PIN thì báo tạo PIN ở màn khóa. `biometricAvailable()` của màn khóa giữ nguyên nghĩa. Không mở Settings hệ thống và không xin quyền thông báo (`MOB-P1-009`).
- Onboarding ba bước, một lần mỗi cài đặt, chỉ khi phiên đã mở khóa. Bỏ qua và hoàn tất đều ghi cờ và phát `onboarding_completed` một lần. `onboarding_started` một lần khi mở bước đầu. Redirect bỏ qua `/splash`.
- FAQ tĩnh trong l10n. Phản hồi chọn góp ý hoặc lỗi, 1–2000 ký tự, sao chép trên máy. Không tải lên, không ghi nội dung vào log. Chưa có địa chỉ nhận vì [DECISIONS-OPEN #10](../project-state/DECISIONS-OPEN.md).
- Phiên bản hiển thị `0.0.1+1`, khớp `pubspec.yaml`. Điều khoản và chính sách là bản nháp `PRD-P0-002`, ghi rõ chưa có hiệu lực và pháp nhân/kênh liên hệ chưa chốt.

## Layer và quyền riêng tư

`settings/{domain,data,presentation}`. Repository, use case và ViewModel đăng ký abstract. View không gọi repository. Domain không import Flutter. ViewModel không import `material.dart`.

Bản ghi preference chỉ có `theme` và `onboardingCompleted`. Chuỗi phản hồi do use case ghép từ phiên bản, loại và nội dung đã trim; page mới đưa vào clipboard. Analytics chỉ nhận hai event onboarding đã có trong catalog.

## Giới hạn

Không help center, ticket hay SLA (Phase 7). Không endpoint phản hồi. Không quyền thông báo. Chưa native build hoặc E2E staging.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 108 Flutter tests pass (14 tests mới).
