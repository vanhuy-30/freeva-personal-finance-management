# UI ví — MOB-P1-003

Home → **Ví của tôi** (`/wallets`, qua AuthGate). Dùng contract hiện có của
[BE-P1-004](financial-accounts.md); không đổi API hoặc migration.

> **UI v2 (`DS-P2-003`, nhóm D):** màn và luồng theo
> [D-wallets.md](../brand/patterns/D-wallets.md). D1 đã thay danh sách,
> sắp xếp, chi tiết ví, chi tiết thẻ và ví đã ẩn (`/wallets`, `/wallets/sort`,
> `/wallets/hidden`, `/wallets/:id`); thêm/sửa ví vẫn là form cũ tới D2. Sắp xếp
> nay lưu một lần qua `PUT /financial-accounts/order` (mục "Sắp xếp" dưới đây
> mô tả cách cũ). Vào/Ra tháng của ví lấy `summary` lọc một ví, tính cả chuyển
> ví. "Ghi từ ví này" / "Chuyển ví" / "Trả thẻ" mở `/record?from=…&to=…`.
> D2 thay form thêm/sửa (`WalletEditorPage` + `WalletForm`): thẻ chọn loại,
> ô tiền tệ, số tiền gõ có phân cách nghìn (`MoneyInputFormatter`, đọc lại bằng
> chuỗi, không qua double), dư nợ thẻ nhập dương và lưu thành số dư ban đầu âm,
> popup chọn ngày 1–28. Ví có `hasTransactions` hiện ô khoá thay cho loại và
> tiền tệ. "Ẩn ví" không hỏi lại, toast Hoàn tác khôi phục ngay. Các mục
> "Hành vi" và "Sắp xếp" dưới đây là bản Phase 1.

## Hành vi

- Danh sách ví đang dùng và bộ lọc ví đã ẩn; tên, loại, số dư và mã tiền tệ.
- Tạo/sửa tiền mặt, ngân hàng, ví điện tử, thẻ tín dụng. Cấu hình hạn mức,
  số trả tối thiểu (`BE-P2-E07`), ngày chốt/thanh toán thẻ không bắt buộc;
  ngày hợp lệ 1–28. Chi tiết thẻ hiện dư nợ, hạn mức còn và số trả tối thiểu.
- Số dư ban đầu cho phép âm và chỉ sửa để đính chính. Backend chặn đổi loại/
  tiền tệ sau khi có giao dịch; API chưa trả cờ khóa nên UI hiển thị hướng dẫn
  và lỗi khi backend từ chối, giữ nguyên bản nháp.
- Nút lên/xuống sắp xếp ví đang dùng, có tooltip vi/en và khóa ở hai đầu.
  Tải đủ các trang `status=all&pageSize=100` trước khi sắp xếp.
- Ẩn có xác nhận, ánh xạ `archived: true`; xem ví đã ẩn để khôi phục bằng
  `archived: false`. Không xóa giao dịch hoặc số dư.
- Loading, danh sách trống, lỗi, tải lại, giữ bản nháp khi lưu thất bại.
  Màn hình cuộn và nút dùng Wrap cho màn nhỏ/chữ lớn.

## Layer, tiền và quyền riêng tư

`wallets/{domain,data,presentation}`; repository/use case/ViewModel đăng ký
abstract qua injectable/get_it. View chỉ gọi ViewModel; domain không import
Flutter. Adapter dùng AuthorizedApi để lấy session hiện tại, không log dữ liệu.

Tiền ở domain là `BigInt`, HTTP là string integer. Input là đơn vị tiền tệ chính,
không phân cách hàng nghìn; dấu thập phân theo locale (`vi`: dấu phẩy, `en`:
dấu chấm). `minorDigits` lấy từ currency catalog; dư chữ số thập phân bị từ chối,
không làm tròn. Formatter tách phần nguyên/lẻ bằng chuỗi, lấy separator từ intl;
không chuyển tiền qua `double`, kể cả balance derived vượt int64. Không cộng
số dư khác tiền tệ hoặc tự quy đổi FX.

Mỗi editor tạo UUID v4 và giữ cùng `clientId` khi retry POST trong editor đó.
PATCH gửi version đọc gần nhất; conflict yêu cầu quay lại danh sách tải lại,
không tự ghi đè. Khi đóng editor rồi mở lại sẽ tạo clientId mới: nếu mất response
POST, nên tải lại danh sách trước khi tạo lần nữa. Chưa có hàng đợi sync/offline.

Thay đổi auth stage xóa state tài chính, vô hiệu hóa kết quả request cũ bằng
request epoch. Editor có AuthGate riêng, đóng và bỏ bản nháp khi khóa/đăng xuất.
Unlock tải lại dữ liệu; 401 chuyển về auth. Không cache ví bền vững trên thiết bị.

## Sắp xếp và giới hạn API

API chưa có batch reorder nguyên tử. Mobile gán sortOrder liên tiếp cho thứ tự
mới bằng PATCH tuần tự, giữ version trả về từng ví. Khi một request lỗi, dừng
chuỗi ghi, hiển thị khả năng lưu một phần và khóa mutation đến khi tải lại thành
công. Không rollback giả ở client; các PATCH đã thành công vẫn có hiệu lực.
Request đang gửi trước khi khóa có thể hoàn tất trên server; mobile bỏ response
và không gửi tiếp các PATCH còn lại. Khi nhiều client sửa đồng thời, version
ngăn ghi đè trên cùng ví; chưa đảm bảo snapshot nguyên tử xuyên các trang list.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 61 Flutter tests pass (11 tests mới).

Test bao phủ int64/derived BigInt, VND/USD vi/en, validation trước ghi, serialization,
phân trang, thứ tự trùng sortOrder, archive/restore/version, lỗi reorder một phần,
retry clientId, conflict, session hết hạn và late response sau khóa. Widget test
kiểm tra danh sách/ẩn/sắp xếp và editor 320px với text scale 2.

Trước phát hành cần backend triển khai BE-P1-004 và profile/options; smoke trên
thiết bị với API thật: tạo bốn loại ví, sửa, đổi thứ tự rồi mở lại, ẩn/khôi phục,
ngắt mạng khi ghi, khóa/unlock editor và xung đột từ hai client. Chưa kiểm chứng
E2E staging hoặc native build trong task này.
