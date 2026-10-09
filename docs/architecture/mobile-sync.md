# Hàng đợi offline giao dịch — MOB-P1-008

Home và danh sách giao dịch hiện trạng thái sync. Có mạng vẫn gọi CRUD hiện có. `AuthError.network` mới đưa mutation vào hàng đợi và gửi lại bằng `POST /api/v1/sync` của [BE-P1-009](sync.md). Không đổi API.

## Hành vi

- Tạo, sửa, xóa và khôi phục giao dịch. Mất mạng thì lưu cục bộ, đóng editor như đã ghi, và không tải lại số dư. Số dư vẫn do server suy ra.
- Gộp trước khi gửi: sửa bản tạo chưa lên server giữ `clientId`; xóa bản đó thì bỏ khỏi hàng đợi; nhiều lần sửa là một update với version gốc; sửa rồi xóa thành một delete cùng version; xóa rồi khôi phục khi chưa gửi thì bỏ operation.
- Flush khi vừa mở khóa, app trở lại foreground, hoặc bấm Đồng bộ. `schemaVersion` 1, tối đa 50 operation pending, cũ trước. `applied` và `replayed` xóa khỏi hàng đợi rồi tải lại danh sách và ví. `conflict` giữ mục, không ghi đè; `review` khi số tiền khác. `rejected` giữ mục ở trạng thái failed. Mục server không trả vẫn pending. HTTP 409 schema thì dừng và không xóa hàng đợi. Mạng hoặc unavailable tăng `retryCount`.
- Gợi ý trùng không chặn tạo và không đưa id vào analytics. Banner chỉ nói có thể đã có giao dịch tương tự.
- Đăng xuất và quên thiết bị xóa hàng đợi. Khóa PIN không xóa.
- Ghi thành công trên mạng thì bỏ mục trùng `clientId` hoặc id server, để không gửi lại.

## Layer, tiền và quyền riêng tư

`sync/{domain,data,presentation}`. Repository, use case và ViewModel đăng ký abstract. View không gọi repository. Domain không import Flutter. ViewModel không import `material.dart`.

Payload tiền là chuỗi integer. Vault `FlutterSecureStorage`, key `freeva.sync.queue.v1`, tách khỏi preference và vault phiên. Log lỗi đọc hàng đợi không kèm nội dung. Analytics `transaction_created`, `transaction_edited`, `transaction_deleted` một lần lúc user ghi; `sync_failed` không property khi flush lỗi mạng hoặc mục `rejected`.

Banner trên Home và màn giao dịch: số mục chờ, loại và ngày, nút Đồng bộ, conflict/failed có thể bỏ. Chuỗi vi/en. Màu lấy từ theme.

## Giới hạn

Không sync ví hay danh mục, không pull cursor, không CRDT, không last-write-wins, không đối soát. Không cơ sở dữ liệu giao dịch đầy đủ. Update hoặc delete mất response có thể thành `conflict` dù server đã áp; mục đó được giữ để người dùng tải lại. Chưa native build hoặc E2E staging.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 117 Flutter tests pass (9 tests mới).
