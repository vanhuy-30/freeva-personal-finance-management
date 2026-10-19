# Phase 2 — epic

Điều kiện hoàn thành: [phase-02.md](../docs/product/phases/phase-02.md). Chưa băm ticket triển khai trước khi Phase 1 đạt gate sổ cái. `Gate: v1` vẫn là điều kiện product v1.

### BE-P2-E01 / MOB-P2-E01 — Giao dịch định kỳ (module 6)
- Status: todo
- Module: 6
- Gate: post-v1
- Depends: BE-P1-005, MOB-P1-004
- DoD: chu kỳ ngày, tuần, tháng, năm và custom. Có số tiền, ví, danh mục, ngày bắt đầu, ngày kết thúc, lần chạy tới, bật/tắt. Đến hạn tạo giao dịch đúng một lần; retry và sync không nhân đôi. Tắt thì không tạo thêm. Chuyển khoản định kỳ vẫn là hai leg cân bằng. Test tháng không có ngày 31.

### BE-P2-E02 / MOB-P2-E02 — Ngân sách (module 7)
- Status: todo
- Module: 7
- Gate: v1
- Depends: BE-P1-005, BE-P1-006, MOB-P1-006
- DoD: ngân sách tổng tháng và theo danh mục, minor units. Đã chi chỉ tính expense chưa xóa; transfer và income không tính. Mức `<70%` healthy, `70–90%` warning, `>90%` critical, `>100%` over. Ngưỡng cảnh báo mặc định 70, 80, 90, 100 và user sửa được. Home hiện thanh `đã chi / hạn mức` khi có ngân sách. Test một bảng số. Gửi push thuộc `BE-P2-E05`.

### BE-P2-E03 / MOB-P2-E03 — Hóa đơn (module 8)
- Status: todo
- Module: 8
- Gate: post-v1
- Depends: BE-P2-E01
- DoD: hóa đơn một lần hoặc gắn một định kỳ. Có hạn, số cố định hoặc ước tính. Đánh dấu đã trả thì trỏ tới một giao dịch. Quá hạn không tự tạo giao dịch.

### MOB-P2-E04 / BE-P2-E04 — Lịch tài chính bản đầu (module 15)
- Status: todo
- Module: 15
- Gate: post-v1
- Depends: BE-P1-005, BE-P2-E01
- DoD: một tháng hiện giao dịch đã ghi, lần chạy định kỳ và hạn hóa đơn theo timezone hồ sơ.

### BE-P2-E05 / MOB-P2-E05 — Thông báo và giờ yên (module 17)
- Status: todo
- Module: 17
- Gate: post-v1
- Depends: BE-P2-E02
- DoD: từng loại bật tắt được: ngân sách 80% và vượt, nhắc đóng góp mục tiêu, nợ đến hạn, thẻ đến hạn, định kỳ sắp chạy, soát tháng, insight mới, cảnh báo bảo mật. Giờ yên và timezone hồ sơ được tôn trọng. Nội dung không đưa số dư đầy đủ nếu câu thông báo không cần. Chưa có module nguồn thì loại đó tắt và không gửi.

### BE-P2-E06 — Mở rộng báo cáo và search (14, 19)
- Status: todo
- Module: 14, 19
- Gate: post-v1
- Depends: BE-P1-007, BE-P1-008
- DoD: so cùng kỳ trước, savings rate = tiết kiệm / thu nhập, xu hướng thu chi cho 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm và toàn bộ. Top merchant chỉ khi `BE-P1-012` đã có merchant.

### BE-P2-E07 / MOB-P2-E07 — Vòng đời thẻ tín dụng
- Status: todo
- Module: 3
- Gate: post-v1
- Depends: BE-P1-004, BE-P1-007
- DoD: từ hạn mức và số dư suy ra dư nợ và hạn mức còn. Giữ ngày chốt và ngày đến hạn 1–28. Thêm số trả tối thiểu. Cảnh báo sắp đến hạn, dư nợ cao và sắp vượt hạn mức. Không tự trả nợ.

### BE-P2-E08 / MOB-P2-E08 — Soát tháng
- Status: todo
- Module: 14
- Gate: post-v1
- Depends: BE-P1-007
- DoD: một bản cho tháng đã chọn: thu, chi, tiết kiệm, savings rate, top 3 danh mục. Mọi số lấy từ báo cáo, không tính lại ở client. Phần lời AI gắn ở `BE-P5-E04`; bản không AI vẫn đủ số.
