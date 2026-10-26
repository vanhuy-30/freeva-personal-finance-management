# Nhóm H — Đồng bộ

Trạng thái: **chốt thiết kế 2026-10-22**, code H1 xong 2026-10-23 (banner, chip, màn Đồng bộ, popup bỏ); H2 (màn 5 chọn bản, màn 6 sheet trùng) xong cùng ngày. Khác thiết kế ở H1: không có tiến độ "2/3" từng mục (một lô gửi một lần gọi, hiện "Đang gửi n thay đổi" + thanh chạy); chưa có nút "Cập nhật" (chờ lên store) và nút "Sửa" (cần form giao dịch nhận dữ liệu từ hàng đợi); lỗi do dữ liệu chỉ có "Bỏ"; lý do "Danh mục đã bị ẩn" thành "Dữ liệu không còn hợp lệ" vì server chỉ trả `VALIDATION_ERROR`. Task: `DS-P2-003`.
Canvas: trang **05 · Patterns**, hàng H
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md). Hành vi đồng bộ:
[mobile-sync.md](../../architecture/mobile-sync.md).

## Nguyên tắc riêng cho nhóm này

- **Đồng bộ chạy ngầm.** Người dùng chỉ thấy nó khi có việc cần làm hoặc khi đang có thay đổi chưa gửi. Không có màn hay nút "Đồng bộ ngay" trên đường ghi chi.
- **Không mất dữ liệu.** Mọi màn đều nói rõ thay đổi vẫn nằm trên máy cho tới khi gửi xong. Xung đột không bao giờ tự ghi đè.
- **Hai mức:** "Cần bạn xem" (xung đột, lỗi cần sửa; màu cảnh báo) và "Đang chờ gửi" (chỉ chờ mạng; màu trung tính). Không dùng màu đỏ cho trạng thái chờ.
- Không nói chi tiết kỹ thuật: không mã lỗi, không "409", không "hàng đợi", không "phiên bản schema".
- Đồng bộ là màn đẩy (push) từ banner, không có bottom nav.
- Phase 1 chỉ đồng bộ giao dịch; ví và danh mục chưa có trong danh sách.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Banner trên danh sách | Danh sách Giao dịch có dải vàng "2 thay đổi cần bạn xem · 3 thay đổi khác đang chờ gửi", chạm mở màn 2. Dòng giao dịch có chip "Cần xem lại" (vàng) hoặc icon đồng hồ "Chờ đồng bộ" | Chỉ còn mục chờ gửi thì banner trung tính; không có gì thì ẩn banner |
| 2 | Đồng bộ | Thẻ trạng thái "Chưa có mạng · Lần cuối 09:30 hôm nay" + nút "Thử lại". **CẦN BẠN XEM · n:** mỗi mục có loại thay đổi (Thêm/Sửa/Xoá), lý do một dòng ("Đã đổi trên máy khác", "Danh mục đã bị ẩn") và nút "Xem" / "Sửa". **ĐANG CHỜ GỬI · n:** mỗi mục có loại, giờ, số tiền và nút × để bỏ. Cuối màn: "Dữ liệu vẫn nằm trên máy này cho tới khi gửi xong." | "Xem" mở màn 5; "Sửa" mở form sửa giao dịch (nhóm C) |
| 3 | Đang gửi | "Đang gửi 2/3 thay đổi · Có thể dùng app như bình thường", thanh tiến độ, từng mục có dấu tích hoặc vòng xoay | Không chặn thao tác |
| 4 | Đã đồng bộ hết | Minh hoạ nét vẽ tay đám mây có dấu tích, "Đã đồng bộ hết · Lần cuối 09:42 hôm nay" | |
| 5 | Chọn bản giữ lại | "Phở Thìn vừa được sửa ở máy khác. Khác nhau chỗ tô vàng." Hai thẻ chọn: **Bản trên máy này** (giờ bạn sửa) và **Bản đã lưu** (giờ sửa ở máy khác, chọn sẵn). Mỗi thẻ có Số tiền, Danh mục, Ghi chú; trường khác nhau tô `warning`. Nút chính đổi theo lựa chọn: "Giữ bản đã lưu" / "Giữ bản trên máy này" | Chọn sẵn bản đã lưu vì an toàn |
| 6 | Có thể bạn đã ghi rồi (sheet) | "Hai khoản này giống nhau." VỪA GHI (thẻ xanh nhạt) và ĐÃ CÓ. "Giữ cả hai" / "Xoá bản vừa ghi" (ink) | Hiện sau khi lưu, không chặn lưu; xoá có Hoàn tác như nhóm C |
| 7 | Bỏ thay đổi này? (popup) | "Khoản Highlands −55.000 sẽ không được lưu." Giữ lại / Bỏ (đỏ) | Mở từ nút × ở màn 2 |
| 8 | Cần cập nhật app | Thẻ cảnh báo "Cần cập nhật Freeva · Để tiếp tục đồng bộ. Thay đổi vẫn được giữ." + "Cập nhật". Danh sách "ĐANG GIỮ TRÊN MÁY · n" | Thay cho thẻ trạng thái ở màn 2 khi server không nhận bản app này |

## Chữ trên màn

| Trạng thái | Chữ |
|---|---|
| Không mạng | Chưa có mạng · Lần cuối {giờ} |
| Đang gửi | Đang gửi {x}/{n} thay đổi |
| Xong | Đã đồng bộ hết |
| Xung đột | Đã đổi trên máy khác |
| Lỗi do dữ liệu | Danh mục đã bị ẩn (mỗi lý do một câu ngắn) |
| Lỗi khác | Chưa gửi được · Thử lại sau |
| App cũ | Cần cập nhật Freeva |

## Thành phần mới (bổ sung vào design system)

- **Banner trạng thái trên danh sách:** dải bo 16, nền `warning` nhạt khi có mục cần xem, `subtle` khi chỉ chờ gửi; một dòng, mũi tên phải.
- **Chip/icon trạng thái trên dòng giao dịch:** "Cần xem lại" chip vàng; "Chờ đồng bộ" icon đồng hồ `text.secondary`. Cùng dòng với số tiền.
- **Dòng mục đồng bộ:** icon danh mục, tên, dòng phụ "{loại} · {lý do hoặc giờ}", hành động bên phải (nút chữ hoặc ×).
- **Thẻ so sánh hai bản:** thẻ chọn có radio, bảng khoá–giá trị, đánh dấu khác biệt bằng nền `warning` nhạt.

## Ánh xạ sang code Phase 1

| Code (`sync_item.dart`) | UI |
|---|---|
| `create` / `update` / `delete` / `restore` | Thêm / Sửa / Xoá / Khôi phục |
| `pending` | Đang chờ gửi |
| `conflict` | Cần bạn xem → màn 5 |
| `failed` | Cần bạn xem → lý do + "Sửa" hoặc Thử lại |
| Server từ chối schema (409) | Màn 8, giữ nguyên hàng chờ |
| Gợi ý trùng | Màn 6 |

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Giữ bản trên máy này | Xong (H2), không cần API mới: mục xung đột giữ ảnh chụp bản server (`SyncServerCopy`); chọn giữ bản máy này thì đặt `version` theo bản server rồi gửi lại (sửa/xoá/khôi phục giữ nguyên loại; tạo bị trùng `clientId` thành sửa giao dịch đã có). Không có ảnh chụp (server không đọc được bản đó) thì chỉ có "Bỏ". |
| Lý do lỗi | Xong một phần (H1): app dịch mã lỗi theo mục có sẵn (`ACCOUNT_NOT_FOUND` → ví đã bị xoá, `TRANSACTION_NOT_FOUND`, `VALIDATION_ERROR` → dữ liệu không còn hợp lệ, còn lại → chưa gửi được). Muốn "Danh mục đã bị ẩn" thì API cần mã riêng. |
| Gợi ý trùng dạng sheet | Xong (H2): kết quả `/sync` giữ id giao dịch vừa tạo và id giao dịch đã có; sheet hiện ở màn gốc của tab, mỗi cặp một lần; không đọc được một trong hai bản thì bỏ qua. |
| Giờ đồng bộ lần cuối, tiến độ x/n | Giờ lần cuối xong (lưu cùng hàng đợi, xoá khi đăng xuất). Tiến độ x/n không làm: một lô là một lần gọi. |
| Cập nhật app | Nút mở App Store / Google Play: chưa làm (cần gói `url_launcher` và đường dẫn store khi app lên store). |
| Ví, danh mục | Chưa đồng bộ ở Phase 1; khi có thì dùng cùng màn này. |
| Copy l10n | Thay `syncPending`, `syncConflict`, `syncDuplicate`… bằng chữ ở bảng trên. |
