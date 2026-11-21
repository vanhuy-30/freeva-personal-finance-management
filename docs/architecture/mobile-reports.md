# Tổng quan và báo cáo — MOB-P1-006 / MOB-P2-E08

Home có khối **Tổng quan** và mục **Báo cáo** (`/reports`, qua AuthGate). Contract: [reports.md](reports.md).

## Hành vi

- Tổng quan đọc `GET /reports/net-worth` và `GET /reports/cashflow?period=month` không gửi `on`, để server lấy hôm nay theo timezone của user. Mỗi loại tiền một khối: tài sản, nợ, ròng, rồi thu, chi và dòng tiền của tháng đó.
- Thẻ đầu tháng "Xem lại tháng …" mở `/reports/month-review?on=` với `period.from` của tháng trước (`MOB-P2-E08`).
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
- **Thẻ tổng** (màn đặt tên "Báo cáo tài chính"): Tổng thu nhập, Tổng chi tiêu (không dấu trừ), Tiết kiệm = thu − chi cùng vòng "Tỷ lệ tiết kiệm", Tổng số dư ví (các ví không phải thẻ, cuối kỳ; **không phải tài sản ròng**, cái đó ở Tổng quan) và Chi trung bình/ngày (chia số ngày đã qua của kỳ đang chạy, hoặc cả kỳ). Mỗi số có ▲/▼ phần trăm một chữ số thập phân so với kỳ liền trước (tuần/tháng/năm trước; số dư ví so với cuối kỳ trước; tỷ lệ tiết kiệm đổi bằng "điểm"). Màu theo ý nghĩa: thu, tiết kiệm, số dư tăng là xanh; chi và chi trung bình tăng là đỏ. **Khoảng tuỳ chọn không so sánh gì.** Không hiện khi kỳ trước bằng 0. Kỳ trước gọi `GET /reports/cashflow` kỳ liền trước; số dư ví lấy từ `walletBalances` của chính cashflow.
- **Nhận định:** chỉ khi đang xem tháng hiện tại và `InsightsViewModel` có kết quả cho đúng tháng tài chính đó: hai mục đầu của màn Phân tích, **cùng nguồn** (không tính thêm số nào), cộng nút "Xem tất cả ở Phân tích". Ẩn khi cờ insights tắt, rỗng hoặc tháng khác.
- **Ngân sách:** kỳ Tháng gọi `GET /budgets/current`; tiêu đề "Ngân sách tháng", số có ₫; chưa có thì dòng "Đặt ngân sách tháng" mở `/budgets` ([budgets.md](budgets.md)).
- **Dòng tiền:** `GET /reports/flow`, cộng dồn thu − chi theo điểm (ngày; tháng cho kỳ Năm; tuần cho khoảng dài hơn 31 ngày), trục luôn gồm mốc 0 ("Mốc 0" nét đứt), nhãn cao nhất/thấp nhất và giá trị hiện tại ở trục phải, ô thu lớn nhất / chi lớn nhất. Kỳ không có thu chi: "Chưa có thu chi trong kỳ này". Không vượt quá hôm nay. Lỗi chỉ ẩn khối này (đang tải thì khung xám).
- **Xu hướng:** một lần gọi `/reports/trend` theo kỳ đang xem (không còn công tắc riêng): lỗi chỉ ẩn khối này. Kỳ đang xem tô `data.1`. Khi kỳ **chưa kết thúc**: nhãn cột có dấu `*`, chip "Đang diễn ra" và chú thích "* Tháng 11 đã qua 21/30 ngày"; trung bình vẫn tính mọi cột.
- **Cơ cấu:** Chi · Thu · Ví; tiêu đề "Cơ cấu" kèm phụ đề theo tab. Chi/Thu gộp danh mục con về cha, ba nhóm đầu rồi "Khác" (tổng % luôn 100) và nút "Xem toàn bộ cơ cấu chi tiêu/thu nhập" mở `/reports/breakdown` (nhận `BreakdownPageArgs` qua `extra`, không mở lại bằng deep link): mọi danh mục cha xếp theo số tiền, kèm % và thanh tổng nhiều màu, chạm vào mở chi tiết danh mục. Ví: Vào/Ra/Chuyển ví và số ròng mỗi ví, sắp theo |ròng|, chạm mở chi tiết ví (đã liệt kê hết nên không có nút xem toàn bộ).
- **Nợ và vay, Đầu tư:** `GET /reports/holdings`, chỉ số **của kỳ đang xem** ("Trong tháng 11"): dư nợ thay đổi, đã trả, vay và dùng thẻ thêm, khoản vay sắp đến hạn; lãi/lỗ trong kỳ (không tính tiền đưa vào hay rút ra), đầu tư thêm, đã rút hoặc bán. Tổng và danh sách ở màn riêng ("Chi tiết" mở `/me/debts`, `/me/investments`). Ẩn khi loại tiền đó không có gì hoặc tải lỗi.
- **Nhiều loại tiền:** mỗi lần một loại (chip khi có hơn một), mặc định tiền hồ sơ; không cộng chéo.
- **Trống:** kỳ không có số liệu → minh hoạ + "Về tháng này/tuần này/năm nay" (kỳ hiện tại thì chỉ lời nhắc).
- Chữ lớn / 320 pt: hai ô thu/chi xếp một cột, vòng tỷ lệ xuống dưới số tiết kiệm, biểu đồ tròn đặt chú thích bên dưới, ô thu/chi lớn nhất xếp dọc, số liệu lớn co lại thay vì bị cắt.

### F2: chi tiết danh mục và popup khoảng ngày

- **Chi tiết danh mục** (`/reports/category`, màn đẩy, nhận `CategoryDetailArgs` qua `extra`, không mở lại bằng deep link): chạm một dòng danh mục ở thẻ Phân tích. Dùng chính báo cáo đang xem nên số khớp màn chính, kể cả tháng tài chính. Tổng, "38% tổng chi · N giao dịch", thanh theo danh mục con (dòng của chính cha ghi "(chung)" khi cha còn có con); "Khác" liệt kê từng danh mục bị gộp.
- **Giao dịch lớn nhất:** `GET /transactions?type&categoryId…&from&to&currency&sort=amountDesc&pageSize=3`; N lấy từ `total`. Ẩn khi nhóm có thu chưa phân loại (API không lọc "không danh mục"). "Xem cả N" đặt `TransactionFilter` (loại, danh mục, khoảng tuỳ chọn) rồi mở `/transactions`; danh sách đó chưa lọc theo loại tiền.
- **Popup khoảng ngày:** chip 7/30 ngày qua và Quý này (từ đầu quý dương lịch đến hôm nay), lịch bắt đầu thứ Hai, chạm lần 1 chọn ngày đầu, lần 2 ngày cuối (ngày sớm hơn thì đổi ngày đầu, lần 3 chọn lại). Ngày tương lai và ngày cách ngày đầu quá 3660 ngày bị khoá. Huỷ giữ nguyên kỳ đang xem. Chữ lớn: hai nút xếp dọc.

### Soát tháng (`MOB-P2-E08`)

Màn đẩy `/reports/month-review`: `GET /reports/month-review`. Từ khi làm lại Báo cáo tài chính không còn dòng "Xem bản soát tháng" ở Báo cáo (thông tin đã nằm ở thẻ tổng); vẫn mở được từ thẻ đầu tháng ở Tổng quan và từ chỉ mục tính năng. Client chỉ gắn tên danh mục (`manage()`); không cộng thu − chi, không xếp lại top 3, không nhân tỷ lệ. `savingsRateBps` hiện bằng chia nguyên (3933 → 39,33%); `null` thì gạch. Chip tiền khi có hơn một currency. Kỳ trống: minh họa + về tháng này. Không lời AI.

## Giới hạn

Tài sản ròng theo thời gian, CSV và search chưa có. Màn Báo cáo vẫn tách từng loại tiền; quy đổi chỉ ở Tổng quan và chi tiết ví/giao dịch, chỉ để hiển thị (`MOB-P2-013`). Không hàng đợi offline cho báo cáo/ngân sách.

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
