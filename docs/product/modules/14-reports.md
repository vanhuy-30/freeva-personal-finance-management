# Module 14 — Báo cáo

- **Phase:** 1 cơ bản; mở rộng 2–5
- **Prefix:** `BE`, `MOB`
- **Epic mở rộng:** `BE-P2-E06` (API); UI chuỗi/so kỳ từ field mới là việc mobile sau. Soát tháng: `BE-P2-E08`.

MVP: thu/chi/dòng tiền, theo danh mục và ví, lọc tuần/tháng/khoảng/năm, tài sản / nợ / ròng hiện tại, biểu đồ xu hướng tuần/tháng/năm.

`BE-P2-E06`: so kỳ liền trước, savings rate (`net / income`), top merchant (khi đã có `merchant`), chuỗi thu/chi 7 ngày · 30 ngày · 3/6/12 tháng tài chính · toàn bộ năm. Contract: [reports.md](../../architecture/reports.md).

Sau: tài sản ròng theo thời gian từng ngày, vs ngân sách chi tiết hơn, chi lớn riêng. Xuất CSV/JSON giao dịch thuộc `BE-P1-010`. Excel/PDF là Could.
