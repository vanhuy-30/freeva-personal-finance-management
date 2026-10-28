# Module 7 — Ngân sách

- **Phase:** 2 · **Gate:** v1
- **Prefix:** `BE`, `MOB`
- **Epic:** `BE-P2-E02` / `MOB-P2-E02` (xong cơ bản)

Ngân sách tổng tháng và theo danh mục. Hạn mức mặc định lặp mỗi tháng tài chính; có thể chỉnh riêng từng tháng (override). Đã chi / còn lại / %. Mức healthy / warning / critical / over; ngưỡng 70/80/90/100 sửa được. Kiến trúc: [budgets.md](../../architecture/budgets.md).

Còn sau: copy tháng trước, loại trừ từng giao dịch, push (`BE-P2-E05`).
