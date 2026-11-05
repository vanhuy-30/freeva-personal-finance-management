# Phase 4 — epic

[phase-04.md](../docs/product/phases/phase-04.md). Theo dõi tài sản/đầu tư và tài sản ròng theo thời gian là `Gate: v1` từ 2026-11-02 (quyết định chủ dự án).

### BE-P4-E01 / MOB-P4-E01 — Tài sản và đầu tư (module 12)
- Status: todo
- Module: 12
- Gate: v1
- Depends: BE-P1-004, BE-P1-007
- DoD: sáu loại tài sản: vàng (chỉ, lượng), cổ phiếu, chứng chỉ quỹ, tiền gửi tiết kiệm (kỳ hạn, lãi suất, ngày đáo hạn; thay module 11), bất động sản, crypto. Vị thế tách khỏi số dư ví tiền. Mua hoặc góp thêm là chuyển tiền từ một ví sang khoản đầu tư và cộng vào giá vốn (gốc), không ghi chi tiêu, không tính ngân sách và báo cáo thu chi. Bán hoặc rút là chuyển về ví; lãi/lỗ thực hiện = tiền về trừ phần giá vốn tương ứng, chỉ hiện trong màn đầu tư, không tính vào thu/chi, ngân sách hay tỷ lệ tiết kiệm. Số lượng là Decimal (crypto tới 8 chữ số thập phân), tiền vẫn minor units. Giá v1 nhập tay, lưu kèm nguồn `manual` và thời điểm; màn hình hiện ngày cập nhật giá. API giá tự động làm sau. ADR chốt cách ghi sổ (giá vốn, lãi/lỗ, chuyển ví ↔ đầu tư) trước khi code. Không tự mua, bán hoặc đưa lời khuyên. Cờ `investment` làm sau cùng `BE-P5-E08`; tới lúc đó module luôn hiện.

### BE-P4-E02 — Tài sản ròng theo thời gian
- Status: todo
- Module: 3, 14
- Gate: v1
- Depends: BE-P1-007, BE-P4-E01
- DoD: snapshot theo tháng tính từ ledger. Biểu đồ 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm, toàn bộ. Không cộng trùng tiền trong ví và tài sản đầu tư. Test một chuỗi tháng với thu, chi, chuyển khoản và một vị thế.

### QA-P4-E01 — Test giá vốn, lãi lỗ, tỷ giá
- Status: todo
- Module: 12
- Gate: v1
- Depends: BE-P4-E01
- DoD: bảng số giá vốn, lãi/lỗ và FX đã chốt, chạy trong test API, gồm vàng theo chỉ/lượng, crypto số lượng lẻ, lãi tiền gửi tới ngày đáo hạn, và một vòng mua → góp thêm → bán một phần. Không dùng số thực dấu phẩy động cho tiền hoặc số lượng.
