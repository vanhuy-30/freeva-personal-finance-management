# UI giao dịch — MOB-P1-004

Home có lối tắt **Ghi giao dịch** và mục danh sách (`/transactions`, qua AuthGate).
Dùng contract hiện có của [BE-P1-005](transactions.md) và đọc danh mục của
[BE-P1-006](categories.md). Không đổi API hoặc migration. Quản lý danh mục là
`MOB-P1-005`. Báo cáo, tìm không dấu, nhãn và hàng đợi offline nằm ngoài task.

## Hành vi

- Composer một màn. Loại mặc định là chi; thu và chuyển nằm cùng màn.
- Ví mặc định là ví còn dùng của giao dịch gần nhất, không thì ví active có
  `sortOrder` nhỏ nhất. Chưa có ví active thì khóa lưu và dẫn tới tạo ví.
- Danh mục gần nhất được chọn sẵn cho chi. Chip gần đây và sheet cây cha-con.
  Chi bắt buộc danh mục, thu tùy chọn, chuyển không gửi danh mục. Tên danh mục
  là dữ liệu, không tự dịch. Không tô chữ bằng `colorToken`.
- `occurredOn` mặc định là hôm nay theo IANA timezone hồ sơ. Có thể chọn quá
  khứ hoặc tương lai trong khoảng 1900–2100. Ngày là lịch `YYYY-MM-DD`, không
  suy từ UTC.
- User nhập số dương. Domain lưu chi âm, thu dương. Chuyển cùng tiền tệ thì
  đích bằng `|nguồn|`. Khác tiền tệ bắt buộc rate chuỗi và `quotedAt`; đích chỉ
  được nhận khi phép đổi ra đúng minor unit, không `double` và không làm tròn.
- Ghi chú optional, tối đa 2000 ký tự. Không gửi nhãn.
- Sửa giữ `version` và `clientId`. Sao chép là POST với `clientId` mới. Xóa mềm
  cả cặp. Khôi phục gửi `deleted: false` và chỉ khi ví còn active.
- Danh sách lọc loại, ghi chú và đang dùng/đã xóa; tải thêm theo trang 50 leg.
  Transfer trên cùng trang được gom một dòng.
- Trước lần đọc danh mục, client gọi `POST /categories/defaults`.

## Layer, tiền và quyền riêng tư

`transactions/{domain,data,presentation}` và đọc danh mục ở
`categories/{domain,data}`. Repository, use case và ViewModel đăng ký abstract
qua injectable/get_it. View chỉ gọi ViewModel. Domain không import Flutter.

Tiền ở domain là `BigInt`. HTTP là string integer. Formatter dùng chung
`core/money` với ví: không phân cách hàng nghìn khi nhập, dấu thập phân theo
locale, dư chữ số thập phân bị từ chối. FX mirror công thức exact của backend.

POST gửi header `Idempotency-Key` trùng `legs[0].clientId`. Cùng editor giữ
nguyên clientId và `quotedAt` khi retry. Conflict yêu cầu tải lại, không tự ghi
đè. Đóng editor rồi mở lại tạo clientId mới.

Đổi auth stage xóa state tài chính và bỏ response cũ. Editor có AuthGate, đóng
khi khóa hoặc đăng xuất. Sau ghi thành công, màn ví được tải lại để số dư
derived cập nhật. Không cache giao dịch bền vững và không log số tiền.

Analytics chỉ `transaction_created` với `type` income/expense/transfer,
`transaction_edited` và `transaction_deleted`. Không amount, số dư hay số tài khoản.

## Giới hạn

Không hàng đợi offline: mất mạng giữ nháp và clientId để gửi lại. Catalog tiền
tệ hiện có VND; nhánh FX vẫn được kiểm tra khi hai ví khác mã. Chưa native
build hoặc E2E staging. Backend giao dịch và migration danh mục cần có trước
khi smoke trên API thật.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 70 Flutter tests pass (9 tests mới).
