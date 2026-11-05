# Module 6 — Giao dịch định kỳ

- **Phase:** 2; phát hiện từ lịch sử ở Phase 5
- **Prefix:** `BE`, `MOB`
- **Task:** `BE-P2-E01` / `MOB-P2-E01`
- **Kiến trúc:** [recurring.md](../../architecture/recurring.md)

Thu/chi/chuyển theo chu kỳ ngày, tuần, tháng, năm và custom (`interval` > 1). Có số tiền, ví, danh mục (chi), ngày bắt đầu/kết thúc, lần chạy tới, bật/tắt.

Đến hạn server tạo giao dịch thường đúng một lần (occurrence ledger + `clientId` ổn định). Retry, worker và sync không nhân đôi. Tắt thì không tạo thêm. Chuyển khoản định kỳ vẫn hai leg cân bằng. Tháng không có ngày 31 được kẹp về ngày cuối tháng.

Chưa làm trong epic này: skip từng kỳ, xác nhận trước khi ghi. Nhắc hộp thư một ngày trước lần chạy thuộc `BE-P2-E05`; push FCM `BE-P2-015`.
