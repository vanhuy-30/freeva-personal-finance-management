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

## Giới hạn

Không so sánh kỳ, ngân sách, chi lớn, tài sản ròng theo thời gian, CSV, search hay quy đổi FX. Không hàng đợi offline. Chưa native build hoặc E2E staging. API báo cáo cần có trước khi smoke trên server thật.

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
