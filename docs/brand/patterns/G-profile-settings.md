# Nhóm G — Cá nhân và cài đặt

Trạng thái: **chốt thiết kế 2026-10-21**, chưa code. Task: `DS-P2-003` (màn Cá nhân/Cài đặt/Giới thiệu/Đăng nhập/Khoá).
Canvas: trang **05 · Patterns**, hàng G
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- **Hồ sơ = thông tin về bạn** (ảnh, tên, email). **Thiết lập tài chính = cách bạn quản lý tiền** (ví, danh mục, nhãn, tiền tệ, ngân sách, tháng tính từ, mục tiêu). **Ứng dụng = cách app chạy** (giao diện, ngôn ngữ, định dạng ngày, múi giờ, thông báo, ẩn số dư, bảo mật). Mỗi thiết lập chỉ có một chỗ sửa.
- Không thu thập dữ liệu app không dùng (thu nhập chính, ngày sinh, giới tính, số điện thoại, địa chỉ).
- Mỗi tài khoản một cách đăng nhập; không có "liên kết Google/Apple".
- Cá nhân là màn gốc của tab (có bottom nav); mọi màn khác trong nhóm không có bottom nav.
- Bật/tắt có hiệu lực ngay, không cần nút lưu. Hành động nguy hiểm (đăng xuất, thu hồi, xoá tài khoản) chữ đỏ, ở cuối, luôn hỏi lại.
- Chip trạng thái và nút hành động luôn cùng dòng với nội dung (nowrap, rút gọn dòng phụ).

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Cá nhân | "Cá nhân". Thẻ hồ sơ (avatar chữ cái, tên, email che). **Thiết lập tài chính:** Ví của tôi · Danh mục · Nhãn · Tiền tệ mặc định · Ngân sách tháng · Tháng tính từ · Mục tiêu (mở A1.2). **Ứng dụng:** Giao diện · Ngôn ngữ · Định dạng ngày · Múi giờ · Thông báo · Ẩn số dư (công tắc) · Bảo mật. **Hỗ trợ:** Câu hỏi thường gặp · Góp ý · Điều khoản và quyền riêng tư. "Đăng xuất" (đỏ), "Phiên bản 0.0.1" | Giá trị hiện tại ở bên phải mỗi dòng; icon màu cho Thiết lập tài chính, xám cho Ứng dụng |
| 2 | Hồ sơ | Avatar 96 + nút máy ảnh. Tên hiển thị. Email (đã xác nhận) · "Đổi". "Xoá tài khoản" (đỏ). "Lưu thay đổi" | |
| 3 | Giao diện (sheet) | 3 thẻ chọn có ảnh thu nhỏ: Sáng · Tối · Theo máy | Đổi ngay khi chọn |
| 4 | Bảo mật | **Mở khoá:** Khoá bằng mã PIN, Mở bằng Face ID (công tắc), Đổi mã PIN. **Đăng nhập:** Phiên đăng nhập (số), Đổi mật khẩu | Face ID khoá khi chưa có PIN, kèm lý do ngắn |
| 5 | Phiên đăng nhập | "Không nhận ra phiên nào thì thu hồi ngay." Máy này + chip "Đang dùng"; phiên khác + nút "Thu hồi" (viền đỏ). "Đăng xuất mọi máy khác" | Dòng phụ "Từ 02/10 · hết hạn 01/11" |
| 6 | Đăng xuất (popup) | "Đăng xuất khỏi máy này?" · "Dữ liệu vẫn nằm trong tài khoản của bạn." · Huỷ / Đăng xuất (đỏ) | |
| 7 | Nhãn | Ô tìm, danh sách nhãn + số giao dịch, nút + tạo nhãn. Chạm nhãn mở danh sách giao dịch đã lọc | |
| 8 | Góp ý | "Bạn muốn nói gì với Freeva?" Thẻ chọn một dòng: Lỗi · Ý tưởng · Lời khen. "Về phần nào?": Ghi chi · Báo cáo · Ví · Danh mục · Giao diện · Khác. Ô nội dung (nhãn đổi theo loại, đếm ký tự). Ảnh chụp màn hình (ảnh nhỏ có nút bỏ + ô thêm). Công tắc "Trả lời tôi qua email". "Gửi góp ý" | Modal |
| 9 | Đã gửi góp ý | Minh hoạ nét vẽ tay máy bay giấy, "Cảm ơn bạn!", "Freeva sẽ đọc và trả lời qua email.", "Xong" (ink) | Khi tắt trả lời qua email thì bỏ vế sau |
| 10 | Câu hỏi thường gặp | Ô tìm, danh sách mở/thu (một câu mở), thẻ cuối "Chưa thấy câu trả lời? · Gửi góp ý cho Freeva" | |
| 11 | Thông báo | **Nhắc nhở:** Nhắc ghi chi (mỗi ngày, giờ chọn được), Tổng kết chi tiêu (mỗi tuần/tháng). **Cảnh báo:** Ngân sách sắp hết (80% và 100%), Thẻ tín dụng đến hạn (trước 3 ngày), Máy mới đăng nhập | Công tắc có hiệu lực ngay; giá trị chạm để đổi (`text.link`) |

## Trường và mục đích

| Trường | Nằm ở | Dùng để |
|---|---|---|
| Ảnh đại diện (ảnh hoặc chữ cái) | Hồ sơ | Nhận diện ở Cá nhân, màn Mở khoá |
| Tên hiển thị | Hồ sơ | Lời chào "Chào Minh" |
| Email | Hồ sơ | Đăng nhập, khôi phục, trả lời góp ý |
| Ngân sách tháng | Thiết lập tài chính | Khối ngân sách ([F-reports.md](F-reports.md)), cảnh báo |
| Mục tiêu (tối đa 2) | Thiết lập tài chính | Thứ tự khối trên Tổng quan ([B-overview.md](B-overview.md)) |
| Tiền tệ mặc định, Tháng tính từ | Thiết lập tài chính | Ví mới; kỳ tháng của báo cáo |
| Định dạng ngày, Múi giờ, Ngôn ngữ | Ứng dụng | Hiển thị ngày giờ, chữ |

## Thành phần mới (bổ sung vào design system)

- **Dòng cài đặt có giá trị:** icon 32, nhãn, giá trị `text.secondary` bên phải, mũi tên.
- **Dòng có hành động chữ:** tiêu đề + dòng phụ một dòng, hành động `text.link` ("Đổi") bên phải.
- **Dòng công tắc có giá trị chạm được:** dòng phụ chứa giá trị `text.link` (giờ nhắc, ngưỡng %).
- **Avatar có nút sửa:** tròn 84, nút máy ảnh 34 nền ink viền màu nền.
- **Thẻ chọn giao diện có ảnh thu nhỏ.**
- **Ô đính kèm ảnh:** ảnh 56×72 bo 12 có nút bỏ, ô thêm viền đứt.
- **Màn cảm ơn:** minh hoạ nét vẽ tay, tiêu đề `headline`, một dòng, nút ink.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Hồ sơ | Thêm tên hiển thị, ảnh đại diện (lưu trữ ảnh) vào profile API; mục tiêu lưu từ onboarding. |
| Ngân sách tháng | `BE-P2-E02`. |
| Định dạng ngày | Preference mới (thiết bị hoặc hồ sơ). |
| Thông báo | Thông báo đẩy `BE-P2-E05`; lưu lựa chọn từng loại, giờ nhắc, nhịp tổng kết, ngưỡng ngân sách. |
| Đổi email | API đổi email có xác nhận lại qua thư. |
| Đổi mật khẩu khi đang đăng nhập | API mới (Phase 1 chỉ có đặt lại qua email). |
| Xoá tài khoản | API + luồng xác nhận (nhập lại mật khẩu hoặc gõ "XOÁ"); thời gian chờ huỷ là quyết định sản phẩm, chưa chốt. Chưa vẽ popup. |
| Góp ý | API nhận nội dung, loại, chủ đề, ảnh, đồng ý liên hệ; Phase 1 chỉ sao chép. Ảnh có thể chứa số dư: nhắc trước khi gửi. |
| Nhãn | API mới có danh sách và tạo; cần đổi tên, xoá, số giao dịch mỗi nhãn. |
| Phiên đăng nhập | API không có tên máy; hiện "Máy này" / "Phiên khác". |
| Copy l10n | Thay chuỗi dài (`profileCurrencyHint`, `profileFiscalHint`, `feedbackHelp`, `authForgetHelp`…) bằng chữ ngắn ở trên; bỏ "(nháp)" khỏi tên mục pháp lý khi có bản chính thức. |
