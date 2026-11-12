# Điều đáng chú ý (insight cơ bản) — BE-P5-E04 / MOB-P5-E04

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `GET /api/v1/insights`. Màn: board S.1 (thẻ trên Tổng quan), S.2 (Phân tích) — [pattern](../brand/patterns/R-suggestions-insights.md).

## Chức năng

Nêu tối đa bốn điều trong tháng tài chính đang chạy, mỗi điều có số thật từ sổ và một hình nhỏ trên app. Tính bằng quy tắc mỗi lần gọi, **không lưu** (chốt 2026-11-11), không gọi model, không gửi dữ liệu ra ngoài. Cờ `insights` tắt hoặc user tắt Gợi ý tự động (`AutoSuggestPolicy`) thì trả danh sách rỗng và không đọc sổ.

## Quy tắc (`domain/insight.ts`, thuần)

Chỉ khoản chi/hoàn tiền còn sống, cùng tiền tệ hồ sơ; hoàn tiền trừ vào chi. Danh mục con gộp vào danh mục gốc. "Cùng kỳ tháng trước" = cùng số ngày từ đầu tháng tài chính trước.

| Thứ tự | Loại | Khi nào |
|---|---|---|
| 1 | `budget_risk` | Ngân sách cả tháng hoặc một danh mục đã dùng ≥ `insights.budgetRiskPercent` (80). Chọn dòng có tỷ lệ cao nhất. Ngân sách khác tiền tệ hồ sơ thì bỏ. |
| 2 | `outlier` | Một khoản tháng này ≥ `insights.outlierMultiplier` (2) lần trung bình một khoản của danh mục trong `insights.outlierMonths` (3) tháng trước; danh mục cần ≥ `insights.minMonths` (2) tháng có dữ liệu. Chọn khoản lệch nhất. |
| 3 | `category_change` | Danh mục tăng nhiều nhất (theo số tiền) so với cùng kỳ, tăng ≥ `insights.minChangePercent` (15%); không có thì danh mục giảm nhiều nhất. Tháng trước bằng 0 thì không so. |
| 4 | `spend_trend` | Tổng chi từ đầu tháng so với cùng kỳ, chênh ≥ 15%. |

Chưa đủ `insights.minMonths` tháng có dữ liệu: `changePercent = null`, app nói câu không có số ("Ăn uống tháng này nhiều hơn tháng trước"). Không bịa phần trăm. Tổng quan hiện mục đầu tiên.

## API

`{ currencyCode, period: { from, to, today } | null, items }`; tiền là chuỗi minor units. Mỗi mục có `kind` và số cho câu và hình (danh mục có tên, icon, màu; `outlier` có `transactionId` để mở chi tiết). App dựng câu từ mẫu l10n theo `kind`.

## Cấu hình

`insights.budgetRiskPercent` (80, 50–100), `insights.minChangePercent` (15, 5–100), `insights.outlierMultiplier` (2, 2–10), `insights.outlierMonths` (3, 1–12), `insights.minMonths` (2, 1–12, ≤ `outlierMonths`).

## Code

Module `insights`: domain thuần, repository Prisma (hồ sơ, sổ trong khoảng ngày), service (kỳ tài chính từ `reports/domain/report.ts`, ngân sách qua `BudgetService`), controller. Test: `insight.spec.ts`, `test/insights.integration-spec.ts`.

## App (MOB-P5-E04)

Feature `lib/features/insights/`: model `Insight` (sealed, bốn loại; loại lạ bị bỏ qua để bản app cũ không lỗi), `InsightsViewModel` dùng chung cho Tổng quan và Phân tích (cờ `insights` tắt thì không gọi API; lỗi chỉ ẩn thẻ). Câu dựng trong app từ mẫu l10n theo `kind`; `changePercent = null` thì câu không có số.

- **S.1** trong `OverviewBlocks`: dưới thẻ "Xem lại tháng N" khi thẻ đó hiện, không thì dưới khối "Chi tháng". Nhãn "Đáng chú ý", "Xem cả N" (một mục: "Xem phân tích"), câu và hình của mục đầu. Tải lại mỗi khi Tổng quan có dữ liệu mới (lần đầu, kéo làm mới, quay lại). Chạm mở S.2.
- **S.2** `/insights`: quay lại, "Phân tích", nút cài đặt (mở Gợi ý tự động), "ĐÁNG CHÚ Ý · N", các thẻ, "Tính từ sổ của bạn, cập nhật mỗi ngày."; kéo làm mới, khung chờ, lỗi có Thử lại, trống "Chưa có điều gì đáng chú ý". Thẻ dự báo chi ở đầu màn để `E06`.
- Chạm: vượt ngân sách → Ngân sách tháng; khoản lệch → chi tiết giao dịch; danh mục → Giao dịch lọc theo danh mục từ đầu tháng tới hôm nay; xu hướng → Báo cáo.
- Golden S.1 sáng/tối, S.2; đối chiếu board bằng `design_compare` nhóm `S`.
