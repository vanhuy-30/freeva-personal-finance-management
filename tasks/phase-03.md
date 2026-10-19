# Phase 3 — epic

[phase-03.md](../docs/product/phases/phase-03.md). Chưa băm ticket trước khi Phase 2 đạt gate phase. Mục tiêu vẫn `Gate: v1`.

### BE-P3-E01 / MOB-P3-E01 — Mục tiêu (module 9)
- Status: todo
- Module: 9
- Gate: v1
- Depends: BE-P1-004, BE-P1-005, MOB-P1-006
- DoD: tên, số đích, số hiện tại, ngày đích, ví liên kết, mức đóng góp tháng, icon và màu bằng token. Có sẵn nhóm quỹ khẩn cấp, mua nhà, mua xe, du lịch, học tập, đám cưới, nghỉ hưu để chọn, user vẫn đặt tên riêng. Đóng góp hoặc rút tạo giao dịch đối ứng, hoặc một dòng audit nếu chỉ sửa số đã có. Công thức có test: đích 120000000, hiện có 40000000, còn 10 tháng → cần 8000000 mỗi tháng. Home hiện `hiện tại / đích` và phần trăm. Không tự chuyển tiền.

### BE-P3-E02 / MOB-P3-E02 — Vay và công nợ (module 10)
- Status: todo
- Module: 10
- Gate: post-v1
- Depends: BE-P1-005
- DoD: loại thẻ, vay cá nhân, vay mua nhà, nợ người quen, khác. Có gốc, dư nợ, lãi suất, số tiền mỗi kỳ, tần suất, ngày đến hạn, ngày bắt đầu, ngày kết thúc. Màn hình tổng nợ, đã trả, còn lại. Mỗi lần trả là một giao dịch. Bộ test lãi dùng số cố định, không `double`. Không biến app thành sản phẩm cho vay.

### BE-P3-E03 / MOB-P3-E03 — Tiền gửi có kỳ hạn (module 11)
- Status: todo
- Module: 11
- Gate: post-v1
- Depends: BE-P1-004
- DoD: một khoản gửi gắn một ví, lãi có công thức và test, không cộng trùng số dư ví. Spec v1 không yêu cầu module này. Được đóng wont nếu beta không cần, và ghi quyết định vào module 11.

### BE-P3-E04 — Dự báo số dư theo quy tắc
- Status: todo
- Module: 14, 15
- Gate: post-v1
- Depends: BE-P2-E01
- DoD: dự báo số dư từ số hiện tại cộng các định kỳ đã biết. Màn hình nêu giả định và cho sửa input. Khác forecast AI ở `BE-P5-E06`: không gọi model.
