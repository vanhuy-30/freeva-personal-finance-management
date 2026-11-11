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

## App chỉ chạy khi có cấu hình (MOB-P5-001)

- `ServerConfigBoundary` bọc nội dung app (trong `MaterialApp.router.builder`): khi đã đăng nhập (`setup` hoặc `unlocked`, onboarding cũng cần số) mà chưa có bản cấu hình nào thì hiện vòng chờ, tải lỗi thì hiện một màn "Chưa tải được cài đặt / Thử lại". Màn đăng nhập không chờ cấu hình. Vì vậy bên trong app luôn có số từ server, không có số dự phòng.
- `AppLimits` (domain `server_config`): mọi số sản phẩm có kiểu, dựng từ `ServerConfig` một lần cho mỗi `version`; thiếu khóa nào thì `null` (boundary hiện Thử lại). Use case đọc qua interface `AppLimitsSource.requireLimits`; view đọc `getIt<AppLimitsSource>().requireLimits`; view model dựng tay nhận `AppLimitsSource` qua constructor.
- Tải cấu hình chạy sau frame khi trạng thái đăng nhập đổi, để không đánh dấu widget bẩn giữa lúc dựng.
- Test: `test/support/server_config_fixture.dart` (`testLimits`, `testServerConfigModel`, `registerTestServerConfig` sau `getIt.reset()`), giá trị bằng mặc định backend.

Đã chuyển (PR 1): mốc ngân sách cho chọn/mặc định/tối đa/lớn nhất; dự báo lựa chọn/mặc định/lớn nhất; trả góp lựa chọn/mặc định/nhỏ nhất/lớn nhất; nhắc trước lựa chọn/mặc định/lớn nhất; mức dùng thẻ cao/nguy hiểm; "sắp đến hạn" thẻ và cho mượn; khoảng mặc định tài sản ròng/biểu đồ đầu tư; số dòng top báo cáo; số giao dịch gần đây trên Home; ngày mục tiêu mặc định/xa nhất; bước phút và giờ nhắc mặc định. Chữ có số dựng từ cấu hình (`budgetThresholdsSheetSub`, `budgetThresholdsDefaultHint`, `installmentOtherLabel`). Màn Thông báo: dòng ngân sách nói "Khi chạm mốc bạn chọn" vì server báo đúng các mốc user chọn (BE-P5-001).

## Trước khi đăng nhập và lúc khóa (MOB-P5-001 PR 2)

- Chưa đăng nhập: app tải `GET /api/v1/app-config/public` (chỉ số, không cờ) ngay khi mở, nên màn đăng ký/đặt lại mật khẩu dùng quy tắc từ server. Boundary áp dụng cho mọi trạng thái: chưa có bản nào thì chờ, tải lỗi thì Thử lại.
- Đăng nhập: chuyển sang `/app-config` (cờ của user). Đăng xuất: giữ số, bỏ cờ, tải lại bản công khai. Màn PIN (khóa): dùng bản đã lưu; máy chưa có bản nào thì tải bản công khai.
- `AppLimitsStore` (không phụ thuộc gì) giữ `AppLimits` hiện tại; model cấu hình ghi vào, repository/use case đọc qua `AppLimitsSource`. Tách ra để `AuthRepository` (đường tải cấu hình đi qua nó) đọc số lần sai PIN mà không tạo vòng DI.

Đã chuyển (PR 2): mật khẩu tối thiểu/tối đa/"rất mạnh" (đăng nhập chỉ kiểm tra mức trần), email tối đa, số lần sai PIN, tên hiển thị (60, sửa lệch 50), tên/ghi chú ví, danh mục, nhãn, mục tiêu, khoản vay, định kỳ, đầu tư, cho mượn, giao dịch, nơi chi, góp ý; số nhãn tối đa; ngày đầu kỳ tối đa; onboarding (số mục tiêu, gợi ý thu nhập, phần tiết kiệm, loại mục tiêu); nhập/xuất CSV. Chữ có số dựng từ cấu hình. Màn Thông báo: dòng mục tiêu/soát tháng theo `available` của server. Icon danh mục: chỉ hiện icon server chấp nhận (`iconTokens`); nhóm và icon chọn nhanh vẫn theo board. Phiên bản app đọc bằng `package_info_plus` (`AppVersion`). Còn cứng có chủ đích: ô tìm kiếm 200 ký tự (API chưa có khóa), độ dài PIN 6, màu/icon mục tiêu (token thiết kế).

## Tiền tệ (MOB-P5-001 PR 3)

- Khi đã đăng nhập, bản cấu hình tải kèm danh mục tiền tệ từ `GET /profile/options` (`code`, `minorDigits`, `symbol`, `isDefault`), lưu cùng bản trên máy. `CurrencyCatalog.current` là danh mục dùng chung: `digits(code)`, `symbol(code)` (ký hiệu server, không có thì hiện mã), `defaultCode` (tiền tệ tài khoản mới, server đánh `isDefault`).
- Lớp chặn khi có phiên chờ cả danh mục. Đăng xuất giữ danh mục (không phụ thuộc user).
- Đã bỏ: quy tắc `VND ? 0 : 2`, ký hiệu `₫` viết cứng, `?? 'VND'` (thay bằng `defaultCode` khi hồ sơ chưa tải). Mã không có trong danh mục hiện không có số lẻ.
- Còn có chủ đích: tên đọc màn hình "đồng" và tên tiền tệ (l10n), gợi ý thu nhập onboarding chỉ cho VND (khóa `onboarding.incomeSuggestionsVnd`), hình minh họa `₫` ở Welcome, gallery dev.
- Test: `test/flutter_test_config.dart` nạp danh mục mẫu cho mọi test.

## Dùng trong code

- Cờ: `getIt<FeatureFlagService>().isEnabled(FeatureFlags.insights)` (bản cài đặt là `ServerConfigViewModel`). `LocalFeatureFlagService` luôn tắt đã bỏ.
- Số cấu hình: bọc khối cần số trong `ServerConfigGate(builder: (context, config) => …)` và đọc `config.integer(...)`, `integers`, `moneyMinor` (chuỗi minor units → `BigInt`), `text`, `texts`. Getter trả `null` khi thiếu khóa hoặc sai kiểu; không đoán số.
- Gate: có cấu hình thì vẽ khối; đang tải lần đầu thì để trống; chưa tải được thì hiện `ErrorRetry` "Chưa tải được cài đặt / Kiểm tra mạng rồi thử lại." với nút Thử lại (tải bắt buộc).
- Các màn hiện có chưa đọc khóa nào: chuyển từng số là việc của `MOB-P5-001`.

## Overlay khi dev

Chỉ bản `APP_ENV=dev` chạy debug: `--dart-define=FEATURE_FLAGS_ON=insights,forecast` bật các cờ đó trên máy dev (cộng thêm vào cờ server). Bản staging, prod, release và profile bỏ qua.

## Code

`apps/mobile/lib/features/server_config/`: `domain/server_config.dart` (`ServerConfig`, `FeatureFlags`), `domain/server_config_repository.dart`, `data/server_config_repository_impl.dart`, `data/server_config_vault.dart`, `presentation/viewmodels/server_config_view_model.dart`, `presentation/widgets/server_config_listener.dart`, `presentation/widgets/server_config_gate.dart`, `presentation/server_config_module.dart` (đăng ký làm `FeatureFlagService`). Test: `test/features/server_config/server_config_test.dart`.
