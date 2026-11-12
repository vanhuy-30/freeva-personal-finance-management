# Dự báo chi cuối tháng và ngày dự kiến đạt mục tiêu — BE-P5-E06 / MOB-P5-E06

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `GET /api/v1/spending-forecast`, `GET /api/v1/goals/{id}/forecast`. Màn: board S.2 (thẻ đầu Phân tích), S.3 (Dự báo chi), T.1 (chi tiết mục tiêu) — [pattern](../brand/patterns/R-suggestions-insights.md). Khác [forecast.md](forecast.md) (`BE-P3-E04`: dự báo **số dư** chỉ từ định kỳ và hóa đơn).

## Chức năng

Hai con số **dự đoán**, không phải số đã xảy ra; app ghi rõ trên màn và nêu cách tính. Tính mỗi lần gọi từ sổ của user, không lưu, không gọi model. Cờ `forecast` tắt hoặc user tắt Gợi ý tự động (`AutoSuggestPolicy`) thì `forecast: null`.

## Dự báo chi (`spendForecast`, thuần)

- Đã chi = chi − hoàn tiền từ đầu tháng tài chính đến hôm nay, chỉ tiền tệ hồ sơ.
- Dự báo = đã chi ÷ số ngày đã qua × số ngày của tháng (làm tròn xuống).
- Rủi ro so với ngân sách cả tháng cùng tiền tệ hồ sơ: dự báo < `spendForecast.mediumRiskPercent` (90%) → thấp, ≤ `spendForecast.highRiskPercent` (100%) → vừa, cao hơn → cao. Không có ngân sách: `risk = null`, app so với `previousMonthMinor` (cả tháng trước).
- `dailyAllowanceMinor` = (ngân sách − đã chi) ÷ số ngày còn lại; null khi không có ngân sách, đã vượt hoặc ngày cuối.
- Chưa đủ `spendForecast.minDays` (3) ngày: `status = insufficient`, không có số dự báo.
- Kèm `cumulative` (đã chi cộng dồn từng ngày, cho biểu đồ) và `topCategories` (3 danh mục gốc chi nhiều nhất, con gộp vào cha).

## Ngày dự kiến đạt mục tiêu (`goalForecast`, thuần)

- Mức góp trung bình = (góp − rút) trong `goalForecast.months` (3) tháng dương lịch **đã qua trọn** ÷ số tháng đó. Tháng đang chạy không tính (chốt 2026-11-12), để user chưa góp tháng này không làm số tụt.
- Còn thiếu ÷ mức góp, làm tròn lên = số tháng cần; tháng dự kiến tính từ tháng này. `monthsLate` = tháng dự kiến − tháng hạn (dương là trễ, âm là sớm).
- `reached` khi đã đủ; `insufficient` khi mức góp ≤ 0 (chưa góp, hoặc rút nhiều hơn góp). Theo tiền tệ của mục tiêu. Mục tiêu không phải của user: `404 GOAL_NOT_FOUND`.
- "Cần mỗi tháng để kịp hạn" dùng `requiredPerMonthMinor` sẵn có của mục tiêu.

## Cấu hình

`spendForecast.minDays` (3, 1–15), `spendForecast.mediumRiskPercent` (90, 50–150), `spendForecast.highRiskPercent` (100, 50–200; phải lớn hơn mức vừa), `goalForecast.months` (3, 1–12).

## Code

Module `spend-forecast`: domain thuần, repository Prisma, service (kỳ tài chính từ `reports/domain/report.ts`, ngân sách qua `BudgetService`), hai controller. Test: `spend-forecast.spec.ts`, `test/spend-forecast.integration-spec.ts`.

## App (MOB-P5-E06)

- **S.2** (`lib/features/spend_forecast/`): thẻ ở đầu màn Phân tích, trên "ĐÁNG CHÚ Ý · N", hiện cả khi danh sách điều đáng chú ý trống. Chip rủi ro, số dự báo, thanh đã chi + phần dự báo sọc + vạch ngân sách; không có ngân sách thì bên phải chú thích là "Tháng trước". Chưa đủ ngày: "Chưa đủ dữ liệu, xem lại sau vài ngày", không chạm được. Tải lại mỗi lần mở màn và khi kéo làm mới; lỗi chỉ ẩn thẻ.
- **S.3** `/insights/spending-forecast`: số dự báo, "Vượt ngân sách khoảng…", biểu đồ cộng dồn (vẽ tay, có nhãn đọc màn hình), "Trung bình mỗi ngày" và "Để không vượt, mỗi ngày dưới…" (không có thì "Tháng trước"), 3 danh mục chi nhiều nhất, dòng "Dự đoán… chưa phải số đã chi."; chưa đủ dữ liệu thì màn trống.
- **T.1** (`goals`): ô "Ngày đạt" trên chi tiết đổi thành "Hạn" (form tạo/sửa giữ "Ngày đạt" theo board I.3). Thẻ "Với mức góp gần đây · Dự kiến đạt MM/yyyy", chip Trễ/Sớm N tháng hoặc Kịp hạn, dải mốc Hôm nay → Hạn → Dự kiến (sớm thì Dự kiến ở giữa), dòng mức góp trung bình và, khi trễ, "Góp X mỗi tháng để kịp hạn." Tải khi mở chi tiết và sau Góp thêm / Rút ra; đã đạt, tắt hoặc lỗi thì không có thẻ.
- Golden S.2, S.3 sáng/tối, T.1; đối chiếu board bằng `design_compare` nhóm `S`, `T`.
