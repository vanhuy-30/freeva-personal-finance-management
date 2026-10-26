# Tổng quan và báo cáo — MOB-P1-006

Home có khối **Tổng quan** và mục **Báo cáo** (`/reports`, qua AuthGate). Dùng contract hiện có của
[BE-P1-007](reports.md). Không đổi API hoặc migration.

## Hành vi

- Tổng quan đọc `GET /reports/net-worth` và `GET /reports/cashflow?period=month` không gửi `on`, để server lấy hôm nay theo timezone của user. Mỗi loại tiền một khối: tài sản, nợ, ròng, rồi thu, chi và dòng tiền của tháng đó.
- Màn báo cáo lọc `week`, `month` hoặc `range`. Lần đầu tuần hoặc tháng không gửi `on`. Nút kỳ trước/sau gửi `on` bằng ngày liền trước `from` hoặc liền sau `to` mà server đã trả. Tháng tài chính không tính trên client.
- Khoảng ngày là `from`/`to` lịch `YYYY-MM-DD`, inclusive, `from <= to`, lệch tối đa 3660 ngày. Client từ chối khoảng sai trước khi gọi API. Không gửi `on`.
- `totals` là thu/chi/dòng tiền. Dòng danh mục là lá: không cộng lên cha; tên cha chỉ là phụ đề. `categoryId` null hiện “Chưa phân loại”. Dòng ví gồm chuyển khoản. Tên ví lấy từ danh sách `status=all`, tên danh mục từ `manage()` nên danh mục đã ẩn vẫn hiện nếu còn giao dịch.
- Thiếu tên ví, tên danh mục hoặc số lẻ của loại tiền thì cả lần tải lỗi và có nút tải lại. Không hiện UUID.
- Không cộng số của hai loại tiền. Số tiền là `BigInt`, format theo `minorDigits` của `profile/options`. Thu và chi dùng màu semantic success/danger.
- 401 đưa về đăng nhập. Đổi auth stage tăng epoch và xóa state. `report_viewed` phát một lần khi màn `/reports` tải cashflow thành công trong lượt mở đó. Tổng quan trên Home không phát event.

## Layer và quyền riêng tư

`reports/{domain,data,presentation}`. Repository, use case và ViewModel đăng ký abstract qua injectable/get_it. View chỉ gọi ViewModel. Domain không import Flutter.

Use case tổng quan chỉ ghép net worth, cashflow tháng và catalog tiền tệ. Use case báo cáo còn tải ví và danh mục để gắn tên. `POST /categories/defaults` nằm trong `manage()` và lặp lại an toàn.

Đổi auth stage bỏ response cũ. Không cache báo cáo và không log số tiền, tên ví hay tên danh mục.

## Màn Báo cáo theo thiết kế nhóm F (DS-P2-003, F1)

Thiết kế: [F-reports.md](../brand/patterns/F-reports.md). Backend: `period=year` và `GET /reports/trend` ([reports.md](reports.md)).

- **Kỳ:** Tuần · Tháng · Năm · Tuỳ chọn. Nút trước/sau gửi `on` theo mốc server đã trả; nút sau khoá khi kỳ đang xem chứa hôm nay (ngày của thiết bị). Khoảng tuỳ chọn mở popup lịch (F2).
- **Thẻ tổng:** Thu, Chi, Chi trung bình/ngày (chia số ngày đã qua của kỳ đang chạy, hoặc cả kỳ), Còn lại = thu − chi. "So với kỳ trước" gọi thêm cashflow kỳ liền trước (khoảng tuỳ chọn lùi đúng số ngày của nó); làm tròn % nửa ra xa 0, màu xám, không hiện khi kỳ trước chưa có chi.
- **Xu hướng:** một lần gọi `/reports/trend`, tách riêng với tổng: lỗi chỉ ẩn khối này. Công tắc Tuần/Tháng/Năm của khối chỉ tải lại xu hướng. Kỳ đang xem tô `data.1`; nhãn giá trị rút gọn (`9,32tr`) bớt khi chữ lớn, nhãn trợ năng đọc đủ số.
- **Phân tích:** Chi · Thu gộp danh mục con về cha, ba nhóm đầu rồi "Khác" (tổng % luôn 100). Ví: Vào/Ra/Chuyển ví và số ròng mỗi ví, sắp theo |ròng|, chạm mở chi tiết ví.
- **Nhiều loại tiền:** mỗi lần một loại (chip khi có hơn một), mặc định tiền hồ sơ; không cộng chéo.
- **Ngân sách:** chưa có module, thay bằng dòng "Đặt ngân sách tháng" (chỉ ở kỳ Tháng) bấm ra toast "Ngân sách sắp có".
- **Trống:** kỳ không có số liệu → minh hoạ + "Về tháng này/tuần này/năm nay" (kỳ hiện tại thì chỉ lời nhắc).
- Chữ lớn / 320 pt: tổng xếp một cột, biểu đồ tròn đặt chú thích bên dưới, công tắc xu hướng xuống dòng riêng.

### F2: chi tiết danh mục và popup khoảng ngày

- **Chi tiết danh mục** (`/reports/category`, màn đẩy, nhận `CategoryDetailArgs` qua `extra`, không mở lại bằng deep link): chạm một dòng danh mục ở thẻ Phân tích. Dùng chính báo cáo đang xem nên số khớp màn chính, kể cả tháng tài chính. Tổng, "38% tổng chi · N giao dịch", thanh theo danh mục con (dòng của chính cha ghi "(chung)" khi cha còn có con); "Khác" liệt kê từng danh mục bị gộp.
- **Giao dịch lớn nhất:** `GET /transactions?type&categoryId…&from&to&currency&sort=amountDesc&pageSize=3`; N lấy từ `total`. Ẩn khi nhóm có thu chưa phân loại (API không lọc "không danh mục"). "Xem cả N" đặt `TransactionFilter` (loại, danh mục, khoảng tuỳ chọn) rồi mở `/transactions`; danh sách đó chưa lọc theo loại tiền.
- **Popup khoảng ngày:** chip 7/30 ngày qua và Quý này (từ đầu quý dương lịch đến hôm nay), lịch bắt đầu thứ Hai, chạm lần 1 chọn ngày đầu, lần 2 ngày cuối (ngày sớm hơn thì đổi ngày đầu, lần 3 chọn lại). Ngày tương lai và ngày cách ngày đầu quá 3660 ngày bị khoá. Huỷ giữ nguyên kỳ đang xem. Chữ lớn: hai nút xếp dọc.

## Giới hạn

Chưa có ngân sách, tài sản ròng theo thời gian, CSV, search hay quy đổi FX. Không hàng đợi offline. Chưa native build hoặc E2E staging. API báo cáo cần có trước khi smoke trên server thật.

## Kiểm chứng

Từ `apps/mobile`:

```sh
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```

Kết quả: analyzer sạch, toàn bộ 94 Flutter tests pass (14 tests mới).

Test bao phủ khoảng 3660 ngày, ngày không tồn tại, bigint vượt int64, từ chối JSON number, bước tuần theo mốc server, không bước quá năm 9999, response muộn sau khi khóa, 401, `report_viewed` một lần mỗi lượt mở. Widget test kiểm tra hai loại tiền tách riêng, nhãn chưa phân loại, và màn báo cáo 320px với text scale 2.
