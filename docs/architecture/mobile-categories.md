# UI danh mục — MOB-P1-005

Home có mục **Danh mục** (`/categories`, qua AuthGate). Dùng contract hiện có của
[BE-P1-006](categories.md). Không đổi API hoặc migration. Nhãn và `groupId` nằm
ngoài task. Ghi giao dịch vẫn chỉ đọc danh mục active qua `load()`.

## Hành vi

- Danh sách cây cha-con và bộ lọc danh mục đã ẩn. Tên là dữ liệu, không tự dịch.
  `isSystem` chỉ hiện nhãn “mặc định”; danh mục hệ thống vẫn sửa, ẩn và xóa được.
- Tạo custom: tên trim 1–100, cha tùy chọn, màu và icon từ `GET /categories/options`
  hoặc bỏ trống. Mỗi editor tạo UUID v4 và giữ cùng `clientId` khi retry POST.
- Sửa gửi `version`. Field không đổi thì không gửi. `null` chỉ để xóa cha, màu
  hoặc icon. Không gửi `clientId`, `isSystem`, `groupId`.
- Ẩn cha còn con active bị chặn trên client. Khôi phục và đổi cha để server từ
  chối khi tổ tiên đã ẩn.
- Xóa là xóa vĩnh viễn, không khôi phục. Client chặn khi còn con, kể cả con đã
  ẩn. Hộp thoại cho chọn danh mục active khác để chuyển giao dịch. Thiếu
  replacement khi còn giao dịch (kể cả soft-delete) trả 409 và bắt tải lại.
- Conflict khóa ghi đến khi tải lại thành công. Đổi auth stage xóa state và đóng
  editor. 401 đưa về đăng nhập.
- Badge dùng token brand/semantic trong theme. `color.brand.highlight` và
  `color.brand.muted` chỉ là nền badge, không phải màu chữ. Icon là khóa ngữ
  nghĩa ánh xạ sang glyph Material ở presentation.

## Layer và quyền riêng tư

`categories/{domain,data,presentation}`. Repository, use case và ViewModel đăng
ký abstract qua injectable/get_it. View chỉ gọi ViewModel. Domain không import
Flutter.

`load()` giữ luồng ghi giao dịch: `POST /categories/defaults`, recent, rồi các
trang `status=active`. Màn quản lý gọi `manage()`: cùng bootstrap, các trang
`status=all&pageSize=100`, rồi `/categories/options`. Bootstrap lặp lại an toàn.

Use case từ chối tên rỗng hoặc dài hơn 100, token ngoài catalog, cha đã ẩn,
chu trình hoặc tự tham chiếu, ẩn khi còn con active, và xóa khi còn con. Server
vẫn là nguồn từ chối 409. Version ngoài 1–2147483646 không được gửi.

Đổi auth stage tăng epoch và bỏ response cũ. Không cache danh mục bền vững và
không log tên danh mục. Catalog analytics chưa có event danh mục nên màn này
không phát event mới.

## Giới hạn

Không hàng đợi offline. Không quản lý nhãn hay nhóm. Chưa native build hoặc E2E
staging. Backend và migration danh mục cần có trước khi smoke trên API thật.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 80 Flutter tests pass (10 tests mới).

Test bao phủ phân trang `status=all`, POST cùng `clientId`, PATCH version và
xóa parent bằng null, DELETE có replacement, 409 bắt tải lại, chu trình cha,
chặn ẩn/xóa khi còn con, khóa xóa state và response muộn. Widget test kiểm tra
thụt cây, lọc đã ẩn, và editor 320px với text scale 2.
