# Module 19 — Tìm kiếm

- **Phase:** 1; mở rộng Phase 2
- **Prefix:** `BE`, `MOB`

Ghi chú, số tiền, danh mục, ví, nhãn, cửa hàng (`merchant`), khoảng thời gian. Tiếng Việt không dấu (Should). Contract `GET /api/v1/transactions?search`: [search.md](../../architecture/search.md) (`BE-P1-008`; khớp merchant từ `DS-P2-005`).

`BE-P2-E06` không thêm endpoint search mới — top merchant nằm ở báo cáo ([reports.md](../../architecture/reports.md)). Còn Phase 2: người nhận, bộ lọc lưu, giao dịch có hóa đơn.
