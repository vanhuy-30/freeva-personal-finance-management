# Nhóm N — Dự báo, soát tháng, ngân sách, nhắc

Trạng thái: **chốt thiết kế 2026-11-03**; màn 3 (`MOB-P3-002`), màn 4 (`MOB-P3-003`), màn 5 và 6 (`MOB-P3-006`) đã code. Task: `MOB-P3-E04` (dự báo), `MOB-P3-002` (thẻ soát tháng), `MOB-P3-003` (ngưỡng ngân sách), `MOB-P3-006` (nhắc ghi chi); API xong.
Canvas: trang **07 · Phase 3**, hàng N. Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Dự báo **chỉ cộng các khoản định kỳ và hóa đơn**, tính từ tháng hiện tại; nói rõ trên màn là chưa gồm chi tiêu hằng ngày.
- Tính năng chưa có thông báo ở backend để "Sắp có", không ẩn dòng.
- Sheet và popup luôn nằm trên màn thật.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Báo cáo · lối vào dự báo | Như F.1, thêm dòng "Dự báo số dư" ngay dưới "Xem bản soát tháng" | |
| 2 | Dự báo số dư | Công tắc 3 / 6 / 12 tháng. Thẻ: "Cuối tháng 1 còn khoảng 89.200.000", "+40.950.000 so với hôm nay", cột: Hôm nay và từng tháng (cột cuối primary). Thẻ **Cách tính**: "Bắt đầu từ số dư 48.250.000 · 4 ví · Sửa", "Chỉ gồm định kỳ và hóa đơn, chưa gồm chi tiêu hằng ngày." **KHOẢN ĐƯỢC TÍNH**: từng khoản có công tắc; khoản tắt gạch ngang số tiền | Tắt khoản = `excludeRuleIds`; Sửa số dư = `startingBalanceMinor` |
| 3 | Đầu tháng · thẻ soát tháng | Thẻ "Xem lại tháng 10 · Chi … · Thu …" thêm hai dòng: danh mục tăng nhiều nhất, vượt ngân sách bao nhiêu % | |
| 4 | Ngưỡng cảnh báo ngân sách (sheet trên Ngân sách tháng) | "Báo khi đã dùng · Chọn tối đa 4 mốc." Chip 70 / 80 / 90 / 100% có dấu tích. "Mặc định 80% và 100%." "Lưu" | `alertThresholds` 1–4 mốc |
| 5 | Thông báo · Phase 3 | **NHẮC NHỞ**: Nhắc ghi chi "Mỗi ngày lúc 21:00" (giờ là liên kết), Định kỳ và hóa đơn, Góp vào mục tiêu (Sắp có), Soát tháng (Sắp có). **CẢNH BÁO**: Ngân sách sắp hết "Khi dùng 80% và 100%" (liên kết sang 4), Nợ đến hạn, **Thẻ tín dụng** "Sắp đến hạn, sắp chạm hạn mức" (công tắc), Máy mới đăng nhập. **GIỜ YÊN** | Bỏ Insight |
| 6 | Chọn giờ nhắc (popup trên 5) | Icon đồng hồ, "Chọn giờ nhắc", "Hôm nào đã ghi thì không nhắc." Bánh xe giờ : phút. Huỷ · "Chọn 21:00" | `dailyLogTime` HH:mm |
| 7 | Hộp thư thông báo (thêm 2026-11-04, thay bản đang chạy) | Quay lại · "Thông báo" · nút cài đặt (mở 5). Chia ngày **HÔM NAY** ("Đọc hết" bên phải) · **HÔM QUA** · **TRƯỚC ĐÓ**, mỗi ngày một thẻ nhóm. Mỗi dòng: icon theo loại, tiêu đề có tên thật ("Tiền điện đến hạn 05/11", "Hà quá hạn trả"), giờ hoặc ngày bên phải, dòng phụ có số tiền. Chưa đọc: tiêu đề 600 + chấm primary 8; đã đọc: tiêu đề 500 `text.onWash`. Nhắc ghi chi có nút "Ghi chi", hóa đơn đến hạn có nút "Đã trả" (mở L.4). Chạm dòng mở màn liên quan | Thay CurInbox (hàng P2 trang 05). Màu icon: hóa đơn amber, thẻ teal, ngân sách và quá hạn red, nhắc ghi chi blue, đăng nhập grey |
| 8 | Hộp thư · chưa có | Chuông 40 trong vòng 96 `tint.blue`, "Chưa có thông báo", "Nhắc hạn và cảnh báo sẽ hiện ở đây.", liên kết "Chọn thông báo muốn nhận" (mở 5) | |

## Thành phần mới

- **Cột dự báo:** cột bo 10/4, rộng 44, nhãn giá trị rút gọn ("65,9tr") trên đầu, cột cuối primary, còn lại `blue.100`.
- **Dòng khoản có công tắc:** số tiền tắt → muted + gạch ngang.
- **Dòng thông báo:** icon 40 bo 12, tiêu đề 15 + giờ 12 muted cùng hàng, dòng phụ 13 tối đa 2 dòng, nút viên thuốc đen cao 32 (nếu có) bên dưới; đường kẻ giữa các dòng thụt 68.
- **Bánh xe giờ trong popup:** giá trị chọn 28 600 trên dải `bg.subtle`, giá trị khác 20 muted.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Dự báo | `GET /forecast` với `months` 3, 6 hoặc 12 (tối đa 12), trả từng tháng `opening/income/expense/closing` và `assumptions` |
| Thông báo | Công tắc theo `PUT /notification-preferences`: `dailyLogEnabled`, `recurringEnabled`, `budgetEnabled`, `debtEnabled`, `cardEnabled`, giờ yên `quietStart/End` |
| Sắp có | Mục tiêu và Soát tháng chưa có loại thông báo ở backend |
| Hộp thư | `GET /notifications`, `POST /notifications/{id}/read`, `POST /notifications/read-all`. Tên trên dòng tra từ ID trong `params` (`ruleId`, `debtId`, `accountId`); `recurring_soon` chưa có `ruleId` nên cần backend thêm mới hiện được tên khoản. Nhóm ngày theo `createdAt` giờ máy |
| Câu hỏi để sau | Dự báo chưa trừ mức chi trung bình; nếu cần thì sửa backend |
