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
