# Hồ sơ tài chính — MOB-P1-002

Từ home chọn **Hồ sơ tài chính**. Hồ sơ thuộc tài khoản đang đăng nhập, lưu ở
`User` qua API; không dùng cài đặt toàn thiết bị hoặc dữ liệu giả.

## Phạm vi và hành vi

- Ngôn ngữ `vi`/`en`; `vi` mặc định. Locale toàn app đổi sau khi API xác nhận lưu.
- Tiền tệ mặc định chọn từ catalog `Currency` trên backend; không quy đổi hoặc
  sửa tiền tệ/số tiền của ví và giao dịch đã có. Database mới hiện chỉ seed `VND`
  khi đăng ký; tiền tệ khác chỉ xuất hiện khi đã được cấu hình trong catalog.
- Múi giờ IANA, mặc định `Asia/Ho_Chi_Minh`; danh sách có tìm kiếm, hỗ trợ `UTC`
  và giữ alias hợp lệ của hồ sơ hiện tại. Backend kiểm tra IANA bằng ICU của Node.
- Ngày bắt đầu tháng tài chính là số nguyên 1–28, mặc định 1. Chưa tính báo cáo
  hay biến đổi `occurredOn`; các use case giao dịch/báo cáo sẽ sử dụng hồ sơ này.
- Có loading, lỗi mạng, thử lại, lưu/hủy bản nháp và xác nhận thành công bằng vi/en.
  Lỗi lưu giữ bản nháp, không đổi locale thành công giả.
- Không thêm họ tên/avatar/quốc gia/định dạng ngày tùy chỉnh trong task bốn trường này.

## Contract và quyền riêng tư

`GET /api/v1/profile`, `PUT /api/v1/profile`, `GET /api/v1/profile/options`
đều dùng `UserBearer`/`AuthGuard`, lấy user ID từ session, `Cache-Control: no-store`.
PUT nhận đủ bốn trường và `version`; DTO từ chối field lạ, sai kiểu và giá trị
ngoài miền. Prisma update theo `(id, version)` và tăng version trong transaction;
lưu từ phiên bản cũ trả `409 PROFILE_CONFLICT`, UI yêu cầu tải lại trước khi sửa.
Không nhận user ID, email hay dữ liệu tiền trong body/response hồ sơ.

Mobile dùng feature data/domain/presentation, `Either`, use case, ViewModel và
abstract DI. `AuthorizedApi` dùng cùng instance auth repository để tái sử dụng
kiểm tra expiry/clear credential khi 401, không đưa token vào profile domain/UI.
401 đưa app về signed out kể cả khi một auth request khác đang chạy.

Profile chỉ được tải khi unlocked. Lock/logout xóa profile và bản nháp khỏi
ViewModel; epoch bỏ qua response cũ. Locale đã lưu giữ trong bộ nhớ khi khóa,
reset về vi khi đăng xuất. Khởi động mới dùng vi tới khi unlock/tải được hồ sơ.
Không cache hồ sơ offline; mất mạng hiển thị lỗi và cho tải lại. Picker mở inline
trong AuthGate để không để lại dialog/overlay phía trên privacy cover.

## Triển khai và kiểm chứng

Cần deploy backend có module profile **trước** bản mobile này. Không có migration
schema mới; tận dụng `User`, `Currency`, `version` hiện có. Chưa deploy staging.

- Flutter analyze sạch; 50 unit/widget tests pass, gồm validation, serialization số
  nguyên, save/reload/cancel, lỗi mạng/409/401, response đến muộn, đổi locale sau
  lưu, màn 320×480 với text scale 2 và privacy khi picker đang mở.
- 82 backend tests pass; HTTP tests kiểm tra auth, ownership, DTO, catalog, IANA và no-store.
- 14 PostgreSQL integration tests pass trong database `auth_test` riêng kiểm tra lưu thật,
  reload, hai request đồng thời (200/409), tài khoản khác và token đã revoke.
- API build pass. Chưa smoke test native device hoặc E2E staging của màn hồ sơ.
