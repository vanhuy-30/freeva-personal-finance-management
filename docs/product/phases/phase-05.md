# Phase 5 — Cấu hình từ server và gợi ý theo quy tắc

Module 26 (cờ, cấu hình), 5, 14, 18 (phần không cần AI). Toàn bộ sau v1.

**Closed** 2026-11-12 (9/9 task còn lại; 4 wont). [STATUS](../../project-state/STATUS.md).

Phạm vi chốt 2026-11-11 (chủ dự án):

- Bỏ nhập sao kê ngân hàng Excel/PDF (`BE-P5-E01`): không làm.
- Chưa chốt hướng AI, nên OCR và Ask Freeva chuyển sang [Phase 8](phase-08.md). Phase 5 chỉ làm phần tính bằng quy tắc và số liệu từ sổ, không gửi dữ liệu ra ngoài.
- Không làm what-if và nút "Không đúng" (2026-11-11): insight và dự báo là số tính từ sổ; gợi ý danh mục sai thì user chọn lại.
- Số và cấu hình mang nghĩa sản phẩm không hardcode trong app: cờ và cấu hình nằm ở server, sửa trên web admin. Áp dụng cả cho phần đã làm ở Phase 0–4.

## Điều kiện hoàn thành

- Cờ và cấu hình đọc từ server, đổi trên web admin có audit; app không còn giá trị nghiệp vụ hardcode trong danh sách rà soát.
- Gợi ý và dự báo không đổi dữ liệu tài chính khi user chưa xác nhận.
- Đo tỷ lệ chấp nhận và tỷ lệ sửa gợi ý danh mục.
- User tắt được gợi ý tự động và xóa dữ liệu đã học.

Epic: [tasks/phase-05.md](../../../tasks/phase-05.md).
