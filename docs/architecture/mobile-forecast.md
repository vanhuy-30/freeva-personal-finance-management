# Dự báo số dư trên app — MOB-P3-E04

Màn **Dự báo số dư** (`/reports/forecast`, qua AuthGate, đẩy từ Báo cáo). Contract: [forecast.md](forecast.md) (`GET /api/v1/forecast`). Thiết kế: [patterns/N-forecast-alerts.md](../brand/patterns/N-forecast-alerts.md) (màn 1–2), board `RepMonth3.dc.html`, `Forecast.dc.html`.

## Hành vi

- Vào từ Báo cáo, kỳ **Tháng**: dòng "Dự báo số dư" ngay dưới "Xem bản soát tháng" (`ForecastLink`).
- Công tắc **3 / 6 / 12 tháng** (`months`, tính cả tháng hiện tại). Thẻ tóm tắt: "Cuối tháng M còn khoảng …" (số dư cuối tháng cuối), "+X so với hôm nay" (cuối kỳ trừ số dư gốc). Cột: Hôm nay và `closingMinor` từng tháng, cột cuối màu primary, nhãn rút gọn ("65,9tr"). Quá nhiều cột thì cuộn ngang (12 tháng).
- Thẻ **Cách tính**: "Bắt đầu từ số dư 48.250.000 · 4 ví" (số ví = ví không lưu trữ, không phải thẻ, cùng tiền tệ hồ sơ; khớp API) hoặc "· bạn nhập" khi đã sửa. Bấm **Sửa** mở sheet "Số dư bắt đầu" (`startingBalanceMinor`); "Dùng tổng số dư các ví" quay về mặc định. Câu "Chỉ gồm định kỳ và hóa đơn, chưa gồm chi tiêu hằng ngày." luôn hiện; có thêm dòng khi `otherCurrencyRuleIds` khác rỗng (khoản khác loại tiền không quy đổi).
- **Khoản được tính**: mỗi định kỳ/hóa đơn trong `includedRuleIds` ∪ `excludedRuleIds` một dòng có công tắc. Tắt = `excludeRuleIds`, số tiền muted và gạch ngang. Thu xếp trước, rồi theo ngày trong tháng. Tên, lịch ("Ngày 5 hằng tháng", "Một lần, 15/11", "Ngày 5 · số ước tính") và icon/màu danh mục lấy từ `GET /recurring` và danh mục đã có; không thêm API.
- Mỗi lần đổi input là một lần gọi lại API. Gọi lỗi thì giữ dự báo cũ, trả input về giá trị trước và hiện dòng lỗi dưới thẻ; lần tải đầu lỗi thì ErrorRetry. Kéo để tải lại.
- "Ẩn số dư" che số dư cuối, số trên cột, chênh lệch và số dư bắt đầu; số tiền từng khoản định kỳ vẫn hiện.

## Layer

`forecast/{domain,data,presentation}`: `BalanceForecast`/`ForecastMonth`/`ForecastAssumptions` (tiền là `BigInt`), `ForecastRepository` + `ForecastRepositoryImpl` (query qua `Uri`, tiền là chuỗi, JSON number bị từ chối), `ForecastUseCases` (chặn `months` ngoài 1–12 và mã tiền tệ sai trước khi gọi), `ForecastViewModel` tạo theo trang (không singleton; xoá state khi đổi auth stage). Không log số tiền hay tên khoản.

## Khác biệt có chủ ý so với board

- Chiều cao cột tính tỷ lệ theo số dư lớn nhất (cao tối đa 108, vùng biểu đồ 150): board đặt 70/96/113/130 nhưng bị co lại khi render, nên theo ý đồ tỷ lệ, không theo số px render. Cao hơn khi chữ phóng to để nhãn không tràn.
- Số dư âm: cột chạm mức tối thiểu 4 (không vẽ cột âm), nhãn có dấu −.
- Board vẽ "Hôm nay" bằng số dư ví; app dùng đúng `startingBalanceMinor` của API.

## Test

Repository (query, chuỗi tiền, JSON number), use case (khoảng, mã tiền tệ, sắp xếp id), ViewModel (tải, đổi khoảng, tắt/bật khoản, sửa và đặt lại số dư, lỗi giữ dự báo cũ) và widget (nhập số dư gửi đúng số). Golden sáng/tối, 1.3×, 12 tháng, sheet số dư, khoản tắt (`forecast_*.png`); golden Báo cáo tháng cập nhật vì thêm dòng. Đối chiếu board ↔ golden: `apps/mobile/tool/design_compare` (nhóm `N`, cặp `Forecast`).
