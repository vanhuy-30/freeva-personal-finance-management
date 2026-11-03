# Nhóm A3 — Onboarding ba câu

Trạng thái: **chốt thiết kế 2026-11-03**, backend xong (`BE-P3-012`), app chưa code. Task: `DS-P3-012` / `MOB-P3-012` (cả backend `BE-P3-012`). Thay các màn Mục tiêu, Thói quen, Ngân sách tháng của [A-onboarding-auth.md](A-onboarding-auth.md); các bước tài khoản, PIN, ví giữ nguyên.
Canvas: trang **07 · Phase 3**, hàng A3. Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Sau khi tạo tài khoản chỉ hỏi **ba câu**, câu nào cũng "Để sau" được, rồi tới bước ví và số dư như cũ.
- Thanh tiến độ 1/3, 2/3, 3/3; nút "Tiếp tục" đen bên phải, "Để sau" bên trái.
- Gợi ý ngân sách chỉ hiện khi có thu nhập.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Mục tiêu sử dụng | "Freeva giúp bạn việc gì?" · "Chọn tối đa 2." Ba thẻ: Quản lý chi tiêu, Tiết kiệm, Quản lý ngân sách | Chi tiêu → khối "Chi tháng" đầu Tổng quan + mời bật nhắc (màn 5). Tiết kiệm → khối mục tiêu (I.6). Ngân sách → khối ngân sách + màn 4 |
| 2 | Thu nhập | **"Thu nhập mỗi tháng khoảng bao nhiêu?"** · "Để gợi ý ngân sách vừa sức." Số lớn có gạch chân, chip 10 / 15 / 25 / 40 triệu. "Nhập số gần đúng, sửa lại được trong Cá nhân." | Lưu `monthlyIncomeMinor` |
| 3 | Mục tiêu tiết kiệm | "Bạn để dành cho việc gì?" Chip có icon (Quỹ khẩn cấp, Mua nhà, Mua xe, Du lịch, Học tập, Đám cưới, Khác). Cần có + Đến khi. Thẻ xanh "Mỗi tháng cần để dành 6.000.000 · 24% thu nhập" | Tạo mục tiêu thật (`BE-P3-E01`) |
| 4 | Gợi ý ngân sách | "Mỗi tháng nên chi khoảng" 19.000.000. Thanh hai màu (chi tiêu / để dành). Thu nhập, "Để dành cho Mua nhà −6.000.000", Chi tiêu. "Sửa được bất cứ lúc nào trong Ngân sách tháng." "Dùng mức này" · "Để sau" | **Chưa có mục tiêu:** dòng để dành thành "Để dành 20% thu nhập −5.000.000", nên chi 20.000.000, thêm câu "Chưa có mục tiêu nên tạm để dành 20%." (ghi chú trên canvas, không vẽ màn riêng) |
| 5 | Mời bật nhắc ghi chi (sheet trên Tổng quan) | Sau giao dịch đầu tiên, nếu đã chọn "Quản lý chi tiêu": icon chuông, "Nhắc ghi chi mỗi tối?", "Hôm nào đã ghi thì không nhắc." Ô Giờ nhắc 21:00. "Bật nhắc" · "Để sau" | Chỉ hỏi một lần |

## Quy tắc gợi ý ngân sách

- Có mục tiêu: **thu nhập − số cần để dành mỗi tháng** của mục tiêu.
- Chưa có mục tiêu: **thu nhập × 80%** (để dành 20%).
- "Dùng mức này" tạo ngân sách tháng; "Để sau" không tạo gì.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Mục tiêu sử dụng | `goals` còn `track`, `save`, `budget`; `emergency` gộp vào `save`, bỏ `debt`, `understand` (migration ở `BE-P3-012`) |
| Bỏ câu cũ | Xoá `trackingHabit`, `reviewCadence`, `onboardingBudgetMinor` |
| Nhắc ghi chi | Bật `dailyLogEnabled` + `dailyLogTime` (nhóm N) |
