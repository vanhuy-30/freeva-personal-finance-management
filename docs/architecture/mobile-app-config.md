# App đọc cờ và cấu hình từ server — MOB-P5-E08

Backend: [app-config.md](app-config.md) (`BE-P5-E08`), sửa trên web admin `/config` (`WA-P5-001`).

## Chức năng

App lấy cờ tính năng và các số cấu hình từ `GET /api/v1/app-config` thay vì hằng số trong code. Staff đổi trên web admin thì app có giá trị mới ở lần tải kế tiếp, không cần phát hành bản mới.

## Luồng

- **Boot:** đọc bản đã lưu trên máy (`flutter_secure_storage`, khóa `freeva.server_config.v1`) trước khi vẽ màn đầu, nên cờ đúng ngay cả khi chưa có mạng.
- **Mở khóa:** `ServerConfigListener` tải từ server khi app vào trạng thái `unlocked`; vừa đăng nhập (từ `signedOut` hoặc `setup`) thì tải ngay.
- **Quay lại app:** tải lại nếu lần tải thành công gần nhất đã hơn 1 giờ (`ServerConfigViewModel.refreshEvery`).
- **`version` đổi:** thay bản trong bộ nhớ và ghi lại bản trên máy; cùng `version` thì không ghi.
- **Đăng xuất:** xóa bản trên máy và trong bộ nhớ (cờ tính theo từng user). Câu trả lời đang chờ lúc đăng xuất bị bỏ.
- **Lỗi mạng:** giữ bản đang có. Chưa từng có bản nào thì mọi cờ coi là tắt và `missing = true`.

## Dùng trong code

- Cờ: `getIt<FeatureFlagService>().isEnabled(FeatureFlags.insights)` (bản cài đặt là `ServerConfigViewModel`). `LocalFeatureFlagService` luôn tắt đã bỏ.
- Số cấu hình: bọc khối cần số trong `ServerConfigGate(builder: (context, config) => …)` và đọc `config.integer(...)`, `integers`, `moneyMinor` (chuỗi minor units → `BigInt`), `text`, `texts`. Getter trả `null` khi thiếu khóa hoặc sai kiểu; không đoán số.
- Gate: có cấu hình thì vẽ khối; đang tải lần đầu thì để trống; chưa tải được thì hiện `ErrorRetry` "Chưa tải được cài đặt / Kiểm tra mạng rồi thử lại." với nút Thử lại (tải bắt buộc).
- Các màn hiện có chưa đọc khóa nào: chuyển từng số là việc của `MOB-P5-001`.

## Overlay khi dev

Chỉ bản `APP_ENV=dev` chạy debug: `--dart-define=FEATURE_FLAGS_ON=insights,forecast` bật các cờ đó trên máy dev (cộng thêm vào cờ server). Bản staging, prod, release và profile bỏ qua.

## Code

`apps/mobile/lib/features/server_config/`: `domain/server_config.dart` (`ServerConfig`, `FeatureFlags`), `domain/server_config_repository.dart`, `data/server_config_repository_impl.dart`, `data/server_config_vault.dart`, `presentation/viewmodels/server_config_view_model.dart`, `presentation/widgets/server_config_listener.dart`, `presentation/widgets/server_config_gate.dart`, `presentation/server_config_module.dart` (đăng ký làm `FeatureFlagService`). Test: `test/features/server_config/server_config_test.dart`.
