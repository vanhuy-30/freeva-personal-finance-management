# MoSCoW — bản phát hành đầu

Phase 1 trong repo là sổ cái. Product v1 rộng hơn: mục Must bên dưới cộng ngân sách, mục tiêu và insight cơ bản. Bảng lệch: [spec-alignment.md](spec-alignment.md).

## Must (Phase 1)

- Đăng ký/đăng nhập/reset mật khẩu và khóa app.
- Hồ sơ, tiền tệ, múi giờ, kỳ tài chính.
- Ví tiền mặt, ngân hàng, ví điện tử, thẻ tín dụng.
- Thu, chi, chuyển khoản, danh mục, tìm kiếm cơ bản.
- Tổng quan thu chi, số dư, tổng tài sản và nợ.
- Đồng bộ, chống trùng, backup, export, xóa tài khoản.
- Bảo mật, privacy, crash monitoring, kênh báo lỗi.

## Must thêm để đủ product v1

- Ngân sách tháng và theo danh mục, thanh tiến độ, ngưỡng cảnh báo.
- Mục tiêu: số đích, đã có, ngày, số cần tiết kiệm mỗi tháng, đóng góp có đối ứng.
- Gợi ý danh mục và insight cơ bản. User sửa hoặc xác nhận. AI không tự ghi sổ.
- Tắt AI và xóa dữ liệu hội thoại.

## Should

- Google / Apple login. API đã có; mobile SDK còn ngoài `MOB-P1-001`.
- Nhãn, merchant, hoàn tác xóa, đối soát thủ công.
- Sinh trắc học trên thiết bị thật, cảnh báo đăng nhập thiết bị mới.
- Offline: hàng đợi local và tự sync lại (`MOB-P1-008`). Tìm không dấu nằm trong `BE-P1-008`.

## Could

- Ảnh hóa đơn, sửa nhiều giao dịch.
- Dashboard/biểu đồ sâu.
- Xuất Excel/PDF, tỷ giá tự động.

## Won't (product v1)

- Kết nối ngân hàng trực tiếp, gia đình, đầu tư.
- OCR, Ask Freeva, forecast, what-if.
- Subscription, admin vận hành đầy đủ.
