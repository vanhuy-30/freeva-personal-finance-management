# Module 5 — Danh mục và nhãn

- **Phase:** 1; học từ xác nhận user ở Phase 5
- **Prefix:** `BE`, `MOB`

Bộ mặc định người Việt. Danh mục tùy chỉnh, con, màu, icon. Ẩn; khi xóa phải chuyển giao dịch. Nhãn (Should, `BE-P1-012`). Danh mục dùng gần đây.

API (`BE-P1-011`) có `kind` expense/income/both và bộ mặc định đủ tên spec; bổ sung
một lần cho tài khoản đã bootstrap, không ghi đè tên đã sửa. Màn Danh mục
có tab Chi · Thu; form ghi lọc theo `kind`. API chưa từ chối kind lệch —
`BE-P2-010`.

API nhãn (`BE-P1-012`): CRUD `/api/v1/tags` theo owner; gắn qua `tagIds` trên giao dịch.
Merchant optional trên thu/chi. UI: `MOB-P1-011`. Chi tiết: [tags.md](../../architecture/tags.md).
