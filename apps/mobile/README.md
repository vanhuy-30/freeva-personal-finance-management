# Mobile (Flutter)

```bash
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Hoặc từ repo root: `make mobile`.

Cấu trúc: `lib/core` + `lib/features/{name}/{data,domain,presentation}`.

## Brand asset — MOB-P1-010

Nguồn artwork: [`docs/brand`](../../docs/brand/README.md). Splash Flutter và
home shell dùng `assets/brand/freeva-brand-symbol.png` nguyên bản, `BoxFit.contain`
và nhãn accessibility qua l10n. Wordmark và copy splash `Your money. Your freedom.` giữ nguyên tiếng Anh
ở cả locale `vi`/`en` theo thiết kế splash đã chốt; các nội dung ứng dụng khác vẫn được dịch.

Tái sinh asset trên macOS (Node.js + `sips` có sẵn trong macOS), từ repo root:

```bash
node apps/mobile/tool/generate_brand_assets.mjs
cd apps/mobile
flutter gen-l10n
flutter analyze
flutter test
```

Script đọc PNG gốc và design tokens, xuất đủ kích thước AppIcon iPhone/iPad/store
(RGB, không alpha), launcher Android legacy cho 5 density và adaptive icon API 26+.
Asset sinh ra được commit; build/CI không cần macOS để tái sinh.

Adaptive icon giữ artwork đã ghép nền của `freeva-app-icon.png`: ảnh nằm trong
viewport 72dp trên canvas 108dp, phần đệm ngoài lấy `color.brand.primary` từ token.
Foreground trong suốt vì repo chưa có bản tách riêng symbol trắng/glass;
không tự vẽ lại logo hoặc tách màu từ raster. Kích thước theo
[Android AdaptiveIconDrawable](https://developer.android.com/reference/android/graphics/drawable/AdaptiveIconDrawable).
Không cung cấp monochrome/themed icon khi chưa có artwork được duyệt.
Task này thay splash Flutter; native launch screen trước frame Flutter vẫn theo scaffold.

Kiểm tra thủ công trước phát hành: launcher mask tròn/squircle trên Android,
AppIcon trên iOS và cold launch splash → home. Phần này cần simulator/device;
widget test không xác nhận được launcher do hệ điều hành render.

Splash Flutter dùng một animation controller 1,8 giây, tự dispose khi rời màn.
Ba mask giữ nguyên pixel artwork; hỗ trợ giảm chuyển động, SafeArea và cuộn
khi chữ lớn/màn hình nhỏ. Home không thêm route transition để tổng thời gian
không vượt 2 giây. Chi tiết copy/motion: [brand docs](../../docs/brand/README.md#splash-mobile--mob-p1-010).

## Auth — MOB-P1-001

Đọc [thiết kế và giới hạn mobile auth](../../docs/architecture/mobile-auth.md).
App dùng email auth API thật; cấu hình origin HTTPS khi chạy:

```bash
flutter run --dart-define=API_BASE_URL=https://freeva-api-staging.onrender.com
```

Backend đích phải triển khai `BE-P1-001`/`BE-P1-002`, endpoint `POST /api/v1/auth/email-step` của `MOB-P1-001`, và cấu hình SMTP để nhận mã
verify/reset. Không truyền secret qua dart-define; URL là cấu hình public.
Không có URL mặc định: thiếu/sai cấu hình báo lỗi và không gửi credential.
Local API cũng cần HTTPS với certificate được thiết bị tin cậy.

Android: SDK compile 35, min 23, NDK 26.3.11579264, AGP 8.6.1/Gradle 8.7 và JDK 17.
Dùng JDK tương thích khi build; không dùng JDK 25 với Gradle này.
iOS: deployment target 12, CocoaPods cho secure storage/local auth.

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator
```

Smoke test trước store: đăng ký/nhận mail, verify, login trước verify, reset thu hồi
phiên, logout; setup PIN/khởi động lại/sai 5 lần; biometric accept/cancel/lockout/
không enrollment; background trong lúc unlock; Android recents/screenshot và iOS
app switcher không lộ nội dung. Mất mạng khi unlock giữ app khóa.

Bản iOS `--no-codesign` chỉ dùng kiểm tra compile. Khi chạy để test Keychain,
cần signing và entitlement Keychain hợp lệ (kể cả simulator). Repo đã cấu hình
`Runner.entitlements` với access group theo bundle ID cho Debug/Profile/Release.
