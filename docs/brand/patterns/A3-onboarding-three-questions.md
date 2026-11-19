# Nhóm A3 — Onboarding ba câu

Trạng thái: **làm lại 2026-11-19** (`BE-P6-002` / `MOB-P6-004`), owner duyệt trên canvas bản 184–190. Bản đầu: `DS-P3-012` / `MOB-P3-012` (2026-11-03). Thay các màn Mục tiêu, Thói quen, Ngân sách tháng của [A-onboarding-auth.md](A-onboarding-auth.md).
Canvas: trang **06 · Onboarding và tài khoản**, khối A1. Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Sau khi tạo tài khoản chỉ hỏi **ba câu**, câu nào cũng "Để sau" được, rồi tới màn **Hoàn tất** và vào app.
- **Ví, mã PIN và ngân sách tháng làm trong app**, không còn trong onboarding: checklist "Bắt đầu nào" nhắc thêm ví và khoá app; ngân sách hỏi bằng sheet khi vào trang chính lần đầu.
- Thanh tiến độ 1/3, 2/3, 3/3; nút "Tiếp tục" đen bên phải, "Để sau" bên trái.
- Thu nhập chỉ hỏi theo **khoảng**, không bắt nhập số. Lưu khoảng là **thu nhập khai báo**, tách hẳn với thu nhập thực tế tính từ giao dịch.

```
Tạo tài khoản → (email: Xác nhận email) → 1 Mục tiêu sử dụng → 2 Thu nhập → 3 Mục tiêu tài chính
→ 4 Hoàn tất → Trang chính lần đầu (+ sheet 5 Đặt ngân sách) → … sheet 6 Nhắc ghi chi
```

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Mục tiêu sử dụng | "Bạn muốn Freeva giúp gì cho mình?" · "Mỗi người có một cách quản lý tài chính riêng. Hãy cho chúng tôi biết điều bạn quan tâm nhất." Dòng nhỏ "Bạn có thể chọn nhiều đáp án". Sáu thẻ một dòng (icon 36, dấu tích tròn): Quản lý thu nhập và chi tiêu · Kiểm soát ngân sách · Tiết kiệm tiền · Quản lý các khoản nợ · Theo dõi tài sản · Cải thiện thói quen tài chính | Chọn bao nhiêu cũng được (server `onboarding.maxGoals`, mặc định 6). Mã: `track`, `budget`, `save`, `debt`, `assets`, `habits`. `track` → mời bật nhắc (màn 6); `save` → khối mục tiêu trên Tổng quan |
| 2 | Thu nhập | "Thu nhập hàng tháng của bạn là bao nhiêu?" · "Thông tin này giúp Freeva đưa ra những gợi ý ngân sách và kế hoạch tài chính phù hợp hơn với bạn." Danh sách radio trong một thẻ: Dưới 5 triệu · 5 – 10 triệu · 10 – 20 triệu · 20 – 40 triệu · Trên 40 triệu · Không muốn chia sẻ. Trên nút: ổ khoá + "Thông tin của bạn được bảo mật và chỉ sử dụng để cá nhân hóa trải nghiệm." | Mốc chia khoảng: server `onboarding.incomeBandsVnd` (5 / 10 / 20 / 40 triệu). Lưu `declaredIncome {minMinor, maxMinor}`; "Không muốn chia sẻ" không gửi gì |
| 3 | Mục tiêu tài chính | "Bạn đang hướng đến mục tiêu tài chính nào?" · "Những mục tiêu nhỏ hôm nay sẽ tạo nên sự khác biệt lớn trong tương lai. Hãy chọn điều bạn muốn đạt được." Chip có icon: Quỹ khẩn cấp, Mua nhà, Mua xe, Du lịch, Học tập, Đám cưới, Nghỉ hưu, Con cái, Kinh doanh, Sức khỏe, Khác. Hai ô "Số tiền" + "Thời hạn" | Không còn thẻ "Mỗi tháng cần để dành". **3b Khác:** thêm ô "Tên mục tiêu" ngay dưới chip, bắt buộc khi chọn Khác. Mục tiêu tạo thật khi có ví |
| 4 | Hoàn tất | Hình con đường chấm lên đỉnh núi có cờ, ba đồng xu, mặt trời, sao nhỏ. "Hành trình tài chính của bạn bắt đầu từ đây!" · "Freeva đã sẵn sàng đồng hành cùng bạn trên hành trình quản lý tiền bạc thông minh và đạt được những mục tiêu tài chính." Nút "Khám phá Freeva" | Vào thẳng Tổng quan, không qua PIN |
| 5 | Đặt ngân sách tháng (sheet trên Tổng quan) | Lần đầu vào trang chính khi chưa có ngân sách: icon biểu đồ tròn, "Đặt ngân sách tháng 11". Ô "Mức chi tối đa" (₫ ở cuối ô), dưới ô "Gợi ý theo thu nhập bạn chọn." "Đặt ngân sách" · "Để sau" | Chỉ hỏi một lần. Số gợi ý = giữa khoảng thu nhập × (100 − `onboarding.savingsSharePercent`)%, ví dụ 10–20 triệu → 12.000.000. Không chia sẻ thu nhập thì ô trống, không có dòng gợi ý |
| 6 | Mời bật nhắc ghi chi (sheet trên Tổng quan) | Sau giao dịch đầu tiên, nếu đã chọn "Quản lý thu nhập và chi tiêu": icon chuông, "Nhắc ghi chi mỗi tối". Ô Giờ nhắc 21:00. "Bật" · "Để sau" | Chỉ hỏi một lần, không cùng lúc với màn 5 |

**Trang chính lần đầu (A1.7):** "Tổng số dư" 0 ₫ (chưa có ví thì không ghi "· 0 ví"). Checklist "Bắt đầu nào 0/3": Thêm ví đầu tiên (nút "Thêm ví", mở màn Thêm ví) · Ghi khoản chi đầu tiên (mũi tên; có ví rồi thì thành nút "Ghi ngay") · Khoá app bằng PIN (khi chưa có PIN).

## Giữa khoảng thu nhập

- Khoảng có trần: (sàn + trần) / 2. "Dưới 5 triệu" → 2.500.000.
- Khoảng mở "Trên 40 triệu": sàn × 5/4 → 50.000.000.
- Tài khoản từ trước khi có khoảng: số cũ thành khoảng [x, x], giữa khoảng là x; Cá nhân hiện số đó.
- Dùng cho: số gợi ý ở màn 5 và "% thu nhập" của mục tiêu.

## Cá nhân → Thu nhập hàng tháng

Dòng hiện khoảng ("10 – 20 triệu") hoặc "Chưa đặt". Chạm mở sheet cùng danh sách khoảng như màn 2; chạm một khoảng là lưu, "Không muốn chia sẻ" xoá thu nhập.
