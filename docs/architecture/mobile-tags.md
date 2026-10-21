# UI merchant và nhãn — MOB-P1-011

Editor giao dịch dùng contract [BE-P1-012](tags.md) và `tagIds` /
`merchant` trên API giao dịch hiện có. Không đổi OpenAPI hay migration.

## Hành vi

- Tạo nhãn từ editor: tên trim 1–100, giữ `clientId` khi retry POST
  `/api/v1/tags`. Tên là dữ liệu, không tự dịch.
- Chip nhãn bật/tắt để gắn hoặc gỡ. Tối đa 20 nhãn trên một giao dịch.
  Gắn được trên thu, chi và chuyển.
- Merchant optional trên thu và chi, tối đa 200 ký tự sau trim. Bỏ trống
  thành `null`. Transfer ẩn ô và luôn gửi `null`.
- Bỏ trống merchant và không chọn nhãn vẫn lưu được.
- Danh sách giao dịch hiện merchant và tên nhãn đã biết trên subtitle;
  id không có trong catalog thì bỏ qua, không hiện UUID.
- Không màn quản lý nhãn riêng (đổi tên / xóa), không search merchant.

## Layer và quyền riêng tư

`tags/{domain,data}` và mở rộng `transactions` cùng hàng đợi
[MOB-P1-008](mobile-sync.md). Repository, use case và ViewModel đăng ký
abstract qua injectable/get_it. View chỉ gọi ViewModel. Domain không
import Flutter.

POST/PATCH giao dịch và body sync create/update luôn gửi `merchant` và
`tagIds` để `null` / `[]` xóa được giá trị cũ. JSON hàng đợi cũ thiếu
key đọc thành `null` và `[]`. Không log merchant hay tên nhãn.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 137 Flutter tests pass. Không native
build hoặc E2E staging trong task này.
