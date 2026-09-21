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
