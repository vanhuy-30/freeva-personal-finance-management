# MoSCoW — bản phát hành đầu

Phase 1 (sổ cái) **closed** 2026-10-21. Product v1 rộng hơn: mục Must bên dưới cộng ngân sách, mục tiêu và theo dõi tài sản/đầu tư. AI (gợi ý danh mục, insight) ra sau v1 từ 2026-11-02. Bảng lệch: [spec-alignment.md](spec-alignment.md).

## Must (Phase 1 — đã đạt)

- Đăng ký/đăng nhập/reset mật khẩu và khóa app.
- Hồ sơ, tiền tệ, múi giờ, kỳ tài chính.
- Ví tiền mặt, ngân hàng, ví điện tử, thẻ tín dụng.
- Thu, chi, chuyển khoản, danh mục, tìm kiếm cơ bản.
- Tổng quan thu chi, số dư, tổng tài sản và nợ.
- Đồng bộ, chống trùng, backup, export, xóa tài khoản.
- Bảo mật, privacy, crash monitoring, kênh báo lỗi.

## Must thêm để đủ product v1

- Ngân sách tháng và theo danh mục, thanh tiến độ, ngưỡng cảnh báo — **đã đạt** (Phase 2).
- Mục tiêu: số đích, đã có, ngày, số cần tiết kiệm mỗi tháng, đóng góp có đối ứng.
- Tài sản và đầu tư: vàng, cổ phiếu, quỹ, tiền gửi, bất động sản, crypto. Giá nhập tay; mua = chuyển từ ví vào giá vốn, không phải chi tiêu. Không mua bán, không lời khuyên.
- Tài sản ròng theo thời gian.
- Đối soát số dư, nhắc ghi chi hằng ngày, hoàn tiền, trả góp thẻ, cho mượn / đi mượn.
- Xuất CSV và nhập CSV từ app khác.
- Gọn lại: hóa đơn gộp vào định kỳ, thẻ soát tháng thay insight, ngưỡng ngân sách 80/100, ẩn quy đổi khi một loại tiền.

## Should

- Google / Apple login. API đã có; mobile SDK còn ngoài `MOB-P1-001`.
- Nhãn, merchant, hoàn tác xóa.
- Sinh trắc học trên thiết bị thật, cảnh báo đăng nhập thiết bị mới.
- Offline: hàng đợi local và tự sync lại (`MOB-P1-008`). Tìm không dấu nằm trong `BE-P1-008`.

## Could

- Ảnh hóa đơn, sửa nhiều giao dịch.
- Dashboard/biểu đồ sâu.
- Xuất Excel/PDF, tỷ giá tự động.

## Won't (product v1)

- Kết nối ngân hàng trực tiếp, gia đình, trading.
- Gợi ý danh mục, insight cơ bản, tắt AI / xóa dữ liệu AI (chuyển ra sau v1 2026-11-02).
- OCR, Ask Freeva, forecast, what-if.
- Subscription, admin vận hành đầy đủ.
