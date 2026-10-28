# Ẩn số dư và cảnh báo phiên — MOB-P1-009

Không đổi API. Khóa app và màn che khi vào nền vẫn thuộc [mobile-auth.md](mobile-auth.md).

## Ẩn số dư

Hai lớp, cùng kiểu app ngân hàng:

- App switcher / recents: AuthGate khóa và che UI; Android `FLAG_SECURE`; iOS cover khi resign active. Không thay bằng việc chỉ che widget số tiền, vì tên ví và ghi chú vẫn có thể lọt vào snapshot.
- Trên màn đang dùng: nút mắt ở thẻ số dư Tổng quan và công tắc **Ẩn số dư** trong Cài đặt. Từ `DS-P2-003` **chỉ ẩn số dư**: tổng số dư, số dư tiền tệ khác, số dư từng ví thành `••••••` (trình đọc màn hình đọc "số dư đã ẩn"). Thu/chi, báo cáo, số tiền giao dịch, hạn mức thẻ vẫn hiện ([B-overview.md](../brand/patterns/B-overview.md)). Ô đang nhập khi sửa ví hoặc ghi giao dịch vẫn hiện số đang gõ. Mặc định hiện số. Cờ `balancesHidden` nằm trong preference thiết bị `freeva.preferences.v1`, cùng bản ghi theme. Bản ghi cũ không có cờ này vẫn hiện số. Đăng xuất không xóa preference.

iOS không chặn screenshot lúc app đang mở. Nút mắt là cách giảm lộ số trong ảnh đó. Android đã chặn screenshot bằng `FLAG_SECURE`.

## Cảnh báo phiên mới

Sau khi vào trạng thái đã mở khóa, app gọi `GET /api/v1/sessions` và so với các id đã thấy trên máy. Id lưu secure storage, key `freeva.seen-sessions.v1` tách theo môi trường và API origin, cùng đường xóa credential khi đăng xuất, quên máy, thu hồi phiên hiện tại hoặc hết hạn. Khóa PIN không xóa danh sách.

- Chưa từng thấy id nào: ghi nhớ mọi phiên đang active, không báo.
- Có id không phải phiên hiện tại và chưa nằm trong danh sách: báo một lần, rồi ghi nhớ mọi id đang active.
- Lỗi mạng hoặc dữ liệu đã thấy bị hỏng: không báo, không ghi đè danh sách.
- Phiên bị thu hồi chỉ biến mất khỏi lần ghi sau, không tạo báo.

Banner trên Home dẫn tới phần quản lý phiên. Thông báo cục bộ chỉ khi người dùng còn bật **Cảnh báo phiên mới** (mặc định bật). Quyền thông báo được xin đúng lúc cảnh báo đầu tiên, không xin lúc mở app. Từ chối quyền thì banner vẫn hiện và không hỏi lại. Đồng ý lần đầu phát `notifications_opt_in`, không kèm property.

Nội dung chỉ nói có phiên đăng nhập khác. Không email, số dư, tên thiết bị, token hay id phiên. Không có payload gắn vào thông báo.

ADR 009 không lưu IP, user agent hay tên thiết bị, nên câu chữ không gọi đây là “thiết bị mới”. Máy đang bị đăng nhập nơi khác chỉ biết khi app được mở khóa lần sau. Push tức thì (FCM) thuộc `BE-P2-015`.

iOS không có khóa Info.plist cho nội dung hộp thoại quyền thông báo cục bộ. Câu giải thích nằm ở công tắc Cài đặt và ở banner.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

`flutter analyze` sạch; toàn bộ 130 Flutter tests pass (13 tests mới), gồm bản preference cũ vẫn hiện số, che số đang đọc nhưng không che ô đang gõ, seed phiên không báo, phiên lạ báo một lần, phiên hiện tại không báo, lỗi mạng không đổi danh sách đã thấy, đăng xuất xóa danh sách, và nội dung thông báo không có số tiền hay email.

Chưa native build hoặc E2E staging. Quyền thông báo trên thiết bị thật cần smoke trước phát hành.
