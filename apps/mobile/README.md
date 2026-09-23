# Mobile (Flutter)

```bash
cd apps/mobile
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run --dart-define-from-file=config/staging.json
```

Repo khóa Flutter `3.47.0` bằng `.fvmrc`. Cài FVM và chạy `fvm install` một lần,
sau đó dùng các lệnh `fvm flutter` / `fvm dart`. Hoặc từ repo root: `make mobile`
(staging, dùng FVM).

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
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
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
fvm flutter run --dart-define=API_BASE_URL=https://freeva-api-staging.onrender.com
```

Backend đích phải triển khai `BE-P1-001`/`BE-P1-002`, endpoint `POST /api/v1/auth/email-step` của `MOB-P1-001`, và cấu hình SMTP để nhận mã
verify/reset. Không truyền secret qua dart-define; URL là cấu hình public.
Không có URL mặc định: thiếu/sai cấu hình báo lỗi và không gửi credential.
Local API cũng cần HTTPS với certificate được thiết bị tin cậy.

Android: SDK compile 35, min 23, NDK 26.3.11579264, AGP 8.6.1/Gradle 8.7 và JDK 17.
Dùng JDK tương thích khi build; không dùng JDK 25 với Gradle này.
iOS: deployment target 12, CocoaPods cho secure storage/local auth.

```bash
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
fvm flutter build ios --simulator
```

Smoke test trước store: đăng ký/nhận mail, verify, login trước verify, reset thu hồi
phiên, logout; setup PIN/khởi động lại/sai 5 lần; biometric accept/cancel/lockout/
không enrollment; background trong lúc unlock; Android recents/screenshot và iOS
app switcher không lộ nội dung. Mất mạng khi unlock giữ app khóa.

Bản iOS `--no-codesign` chỉ dùng kiểm tra compile. Khi chạy để test Keychain,
cần signing và entitlement Keychain hợp lệ (kể cả simulator). Repo đã cấu hình
`Runner.entitlements` với access group theo bundle ID cho Debug/Profile/Release.

## Môi trường mobile — MOB-P1-001

`AppConfig` đọc `APP_ENV` (`dev`, `staging`, `prod`) và `API_BASE_URL` tại compile time. App kiểm tra origin HTTPS trước khi dựng UI; thiếu/sai cấu hình dừng startup với lỗi cấu hình không chứa giá trị nhạy cảm. Không đọc `.env` của backend. `APP_ENV` mặc định `dev` để giữ tương thích lệnh `--dart-define=API_BASE_URL=...` cũ.

- Staging: `config/staging.json` đã có URL Render.
- Dev: copy `config/dev.example.json` thành `config/dev.json`, điền origin HTTPS của backend dev mà thiết bị truy cập và tin cậy certificate.
- Prod: copy `config/prod.example.json` thành `config/prod.json`, điền origin production khi đã xác định. Không có URL production giả định.

Hai file dev/prod thực tế được gitignore. Chỉ chứa cấu hình public; tuyệt đối không đưa SMTP/API key, database URL hoặc auth secret vào mobile. `APP_ENV` là nhãn môi trường, không tự chọn URL thay cho `API_BASE_URL`.

Từ repo root:

```sh
make mobile                         # staging
make mobile MOBILE_ENV=dev
make mobile MOBILE_ENV=prod
# Chỉ dùng SDK hệ thống khi chẩn đoán: make mobile FLUTTER=flutter
```

Từ `apps/mobile`:

```sh
fvm flutter run --dart-define-from-file=config/staging.json
fvm flutter build apk --release --dart-define-from-file=config/prod.json
fvm flutter build ios --release --dart-define-from-file=config/prod.json
```

VS Code: chọn `Freeva (dev)`, `Freeva (staging)` hoặc `Freeva (prod)` trong Run and Debug. Tạo file dev/prod trước khi chọn. Khi đổi env cần dừng/chạy lại hoặc build lại; hot reload không đổi compile-time config.

Đây là cấu hình Dart, chưa phải native flavors: các môi trường dùng chung bundle/application ID, nhưng credential/PIN được lưu riêng theo môi trường và API origin; không gửi session của backend cũ sang backend khác. Phiên lưu trước khi thêm phân tách này không tự migrate, cần login lại một lần. Chưa hỗ trợ cài song song dev/staging/prod. Signing release vẫn cần cấu hình riêng trước phát hành.

## Dev local và staging trên thiết bị — MOB-P1-001

Staging dùng `make mobile-staging` (hoặc `make mobile`), không cần backend local. Dev dùng PostgreSQL và Mailhog trên Mac, HTTPS proxy ở port 8443. Không thay secret Resend đã lưu; lệnh `api-dev` override mail sang Mailhog để không gửi thư thật.

Chuẩn bị trên Mac từ repo root (cần Docker, Node, OpenSSL, FVM; backend `.env` có database localhost và `AUTH_SECRET_KEY`):

```sh
make dev-up
pnpm --filter @freeva/api prisma:migrate:deploy
make dev-https-setup
```

`dev-https-setup` sinh CA/key trong `.local/dev-https` và file cấu hình mobile bị gitignore. Tự lấy IP Wi-Fi `en0`; nếu khác interface, dùng `DEV_LAN_IP=<IPv4 của Mac> make dev-https-setup`. Không chạy migration nếu `.env` đang trỏ DB staging/production.

Mở hai terminal:

```sh
make api-dev           # API local port 4000, mail gửi vào Mailhog
make dev-https         # proxy chỉ loopback cho simulator/emulator
# Hoặc thay dev-https bằng dev-https-lan để dùng điện thoại cùng Wi-Fi
```

Sau đó chọn thiết bị khi Flutter hỏi:

| Lệnh | Backend | Thiết bị |
|---|---|---|
| `make mobile-dev` | `https://localhost:8443` | iOS Simulator |
| `make mobile-dev-android` | `https://10.0.2.2:8443` | Android Emulator chuẩn |
| `make mobile-dev-device` | `https://<IP Wi-Fi Mac>:8443` | iPhone/Android thật, cùng Wi-Fi |
| `make mobile-staging` | HTTPS Render | Mọi thiết bị có Internet |

VS Code có các lựa chọn tương ứng. Điện thoại thật: chạy proxy LAN, cho phép kết nối Node qua firewall macOS và quyền Local Network trên iOS nếu được hỏi; tránh Wi-Fi chặn giao tiếp giữa thiết bị. iPhone thật vẫn cần signing/provisioning thông thường. Khi IP Mac đổi, chạy lại setup, restart proxy và chạy lại app.

`DEV_CA_CERT_BASE64` chỉ chứa **certificate public**, được Dart HTTP client tin cậy riêng trong **debug + APP_ENV=dev**. Certificate chain, expiry và hostname vẫn được kiểm tra; không có `badCertificateCallback`, không cần cài CA vào hệ điều hành. Staging/prod hoặc profile/release có CA dev sẽ bị từ chối. Không copy private key vào mobile hoặc commit `.local`.

Đọc email dev tại `http://localhost:8025`. Kiểm tra HTTPS từ Dart (trong `apps/mobile`):

```sh
fvm dart run tool/check_dev_connection.dart
```

CA có hạn 365 ngày, server certificate 90 ngày. Setup tự cấp lại server certificate gần hết hạn; khi CA hết hạn, dừng proxy, xóa `.local/dev-https`, chạy setup lại và rebuild app. `Ctrl+C` dừng API/proxy; `make down` dừng containers, vẫn giữ volume database.
