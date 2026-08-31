# Glossary

Tránh nhầm “account”.

| Thuật ngữ | Ý nghĩa trong Freeva |
|---|---|
| **User / tài khoản người dùng** | Identity đăng nhập (email, session). Không phải ví tiền. |
| **Financial account / ví** | Tiền mặt, ngân hàng, ví điện tử, thẻ tín dụng, sau này tài khoản đầu tư. Module 3. |
| **Số dư (balance)** | Giá trị hiện tại của một ví, tính từ số dư ban đầu ± giao dịch. Kiểu integer minor units. |
| **Giao dịch (transaction)** | Thu, chi, hoặc **chuyển khoản** (hai leg cân bằng). |
| **Danh mục (category)** | Phân loại chi/thu; có danh mục con. |
| **Nhãn (tag)** | Gắn thêm, không thay danh mục. |
| **Kỳ tài chính (financial month)** | Tháng báo cáo theo ngày bắt đầu do user chọn, không nhất thiết ngày 1. |
| **Ngày tài chính** | Ngày ghi nhận giao dịch theo múi giờ user, không theo UTC wall-clock thuần. |
| **Minor unit** | Đơn vị nhỏ nhất của tiền tệ (VND: 1 đồng). Không dùng số thực nhị phân. |
| **Idempotency key** | Khóa chống tạo trùng khi retry / sync. |
| **Entitlement** | Quyền lợi gói Free/Premium (Phase 7). |
| **Staff user** | Người dùng web admin, khác user app. |

Tiếng Anh trong API: `user`, `financialAccount`, `transaction`, `category`, `tag`, `fxRate`.
