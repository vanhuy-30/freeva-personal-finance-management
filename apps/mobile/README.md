# Mobile (Flutter)

```bash
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Hoặc từ repo root: `make mobile`.

Cấu trúc: `lib/core` + `lib/features/{name}/{data,domain,presentation}`.
