# Phase 5 — epic

[phase-05.md](../docs/product/phases/phase-05.md). Gợi ý danh mục và insight cơ bản là `Gate: v1`. OCR, chat, forecast và what-if không chặn v1.

### BE-P5-E01 / MOB-P5-E01 — Import CSV, Excel, PDF sao kê
- Status: todo
- Module: 13
- Gate: post-v1
- Depends: BE-P1-005, BE-P1-009
- DoD: nhận CSV, Excel và PDF sao kê. Có xem trước, map cột hoặc ví, kết quả từng dòng, hoàn tác cả lô. Trùng với giao dịch đã có thì đánh dấu, không ghi đè im lặng. Không gọi API ngân hàng.

### MOB-P5-E02 / BE-P5-E02 — OCR hóa đơn
- Status: todo
- Module: 13
- Gate: post-v1
- Depends: BE-P1-005, BE-P5-E08
- DoD: ảnh ra merchant, ngày và tổng tiền dạng draft. User xác nhận mới tạo giao dịch. File nằm object storage; database chỉ giữ metadata. Cờ `ocr` tắt thì nút Scan không hiện. Lối `+` mới thêm Scan khi cờ bật.

### BE-P5-E03 / MOB-P5-E03 — Gợi ý danh mục
- Status: todo
- Module: 18, 5
- Gate: v1
- Depends: BE-P1-006, BE-P1-011, BE-P5-E08
- DoD: từ merchant hoặc ghi chú đề xuất một danh mục và độ tin cậy. User sửa được. Hệ thống nhớ mapping merchant → danh mục sau khi user chấp nhận. Có sẵn Grab, Shopee, Lazada, WinMart, Circle K, Highlands, The Coffee House. Không tự lưu giao dịch. Đo tỷ lệ chấp nhận và tỷ lệ sửa. Tắt AI ở `PRD-P5-E01` thì API không đề xuất.

### BE-P5-E04 / MOB-P5-E04 — Insight cơ bản
- Status: todo
- Module: 18
- Gate: v1
- Depends: BE-P1-007, BE-P2-E02, BE-P3-E01, BE-P5-E08
- DoD: ít nhất bốn dạng, mỗi dạng lấy số từ báo cáo hoặc ngân sách hoặc mục tiêu: xu hướng chi, danh mục tăng hoặc giảm, rủi ro vượt ngân sách, giao dịch lệch khỏi mức thường. Home hiện một insight và CTA xem phân tích. Câu không có số khi nguồn không đủ dữ liệu. Không bịa phần trăm. Cờ `ai_insights` tắt thì ẩn card.

### BE-P5-E05 / MOB-P5-E05 — Ask Freeva
- Status: todo
- Module: 18
- Gate: post-v1
- Depends: BE-P1-007, BE-P5-E08, PRD-P5-E01
- DoD: mọi số trong câu trả lời đến từ Finance Query đã có. Model không tự cộng trừ và không dùng bộ nhớ chat làm nguồn số. Thiếu dữ liệu thì nói thiếu. Không tạo giao dịch, không sửa ngân sách, mục tiêu hoặc chuyển tiền. Cờ `ai_chat`.

### BE-P5-E06 / MOB-P5-E06 — Forecast
- Status: todo
- Module: 18
- Gate: post-v1
- Depends: BE-P1-007, BE-P3-E01, BE-P5-E08
- DoD: dự đoán chi cuối tháng, dòng tiền và ngày đạt mục tiêu. Màn hình ghi đây là dự đoán, không phải số đã xảy ra. Cờ `forecast`. Khác `BE-P3-E04`.

### BE-P5-E07 / MOB-P5-E07 — What-if
- Status: todo
- Module: 18
- Gate: post-v1
- Depends: BE-P3-E01, BE-P5-E08
- DoD: nhập một thay đổi chi, ví dụ giảm một danh mục mỗi tháng, và ra số tiết kiệm thêm mỗi tháng, mỗi năm, và mục tiêu đạt sớm hơn bao nhiêu. Không ghi vào sổ. Dùng cờ `forecast`.

### BE-P5-E08 — Feature flag phía server
- Status: todo
- Module: 18, 26
- Gate: v1
- Depends: MOB-P0-003
- DoD: cờ `ai_chat`, `ai_insights`, `ocr`, `forecast`, `investment`, `family`, `bank_import`. Bật theo môi trường, nhóm user hoặc phần trăm. Client đọc server; overlay local chỉ dùng lúc dev. Tắt thì API tương ứng trả lỗi có chủ đích, không chạy ngầm.

### PRD-P5-E01 — Consent và xóa dữ liệu AI
- Status: todo
- Module: 18, 21
- Gate: v1
- Depends: BE-P5-E03
- DoD: user tắt toàn bộ AI, xóa hội thoại và insight đã lưu của chính mình. Consent analytics tách khỏi consent AI. Policy nháp nêu nhà cung cấp AI trước khi bật ở production.
