# Phase 4 — epic

[phase-04.md](../docs/product/phases/phase-04.md)

### BE-P4-E01 / MOB-P4-E01 — Tài sản và đầu tư (module 12)
- Status: todo
- Module: 12
- Gate: post-v1
- Depends: BE-P1-004, BE-P1-007
- DoD: vị thế đầu tư tách khỏi số dư ví tiền. Giá lưu kèm nguồn và thời điểm. Không tự mua, bán hoặc đưa lời khuyên chắc chắn. Cờ `investment` tắt thì ẩn module.

### BE-P4-E02 — Tài sản ròng theo thời gian
- Status: todo
- Module: 3, 14
- Gate: post-v1
- Depends: BE-P1-007, BE-P4-E01
- DoD: snapshot theo tháng tính từ ledger. Biểu đồ 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm, toàn bộ. Không cộng trùng tiền trong ví và tài sản đầu tư. Test một chuỗi tháng với thu, chi, chuyển khoản và một vị thế.

### QA-P4-E01 — Test giá vốn, lãi lỗ, tỷ giá
- Status: todo
- Module: 12
- Gate: post-v1
- Depends: BE-P4-E01
- DoD: bảng số giá vốn, lãi/lỗ và FX đã chốt, chạy trong test API. Không dùng số thực dấu phẩy động cho tiền.
