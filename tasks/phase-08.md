# Phase 8 — epic

[phase-08.md](../docs/product/phases/phase-08.md). Không thuộc product v1.

Mọi tính năng cần AI (mô hình chạy trên máy hoặc dịch vụ bên ngoài) gom về đây ngày 2026-11-11 (quyết định chủ dự án): chưa chốt hướng xây dựng AI. Phase 5 chỉ còn phần chạy bằng quy tắc và số liệu từ sổ.

### PRD-P8-E01 — Chọn hướng AI và nhà cung cấp
- Status: todo
- Module: 18, 21
- Gate: post-v1
- Depends: —
- DoD: ADR chốt AI chạy trên máy hay dùng dịch vụ bên ngoài, nhà cung cấp cụ thể, dữ liệu nào được gửi đi, nơi xử lý so với quyết định lưu dữ liệu ở Việt Nam (DECISIONS-OPEN #5), chi phí và giới hạn gọi. Luật sư xem việc gửi dữ liệu tài chính ra ngoài trước khi bật ở production. Privacy policy §10 ghi tên nhà cung cấp.

### PRD-P8-E02 / MOB-P8-E02 — Đồng ý dùng AI và xóa dữ liệu AI
- Status: todo
- Module: 18, 21
- Gate: post-v1
- Depends: PRD-P8-E01, PRD-P5-E01
- DoD: tính năng gửi dữ liệu cho nhà cung cấp AI chỉ chạy khi user tự bật (opt-in), mặc định tắt. User rút đồng ý và xóa hội thoại, kết quả AI đã lưu của chính mình. Đồng ý AI tách khỏi đồng ý analytics. Xóa tài khoản xóa luôn dữ liệu AI.

### BE-P8-E01 / MOB-P8-E01 — OCR hóa đơn
- Status: todo
- Module: 13
- Gate: post-v1
- Depends: BE-P1-005, BE-P5-E08, PRD-P8-E01, BE-P5-E03
- DoD: ảnh ra merchant, ngày và tổng tiền dạng nháp; danh mục lấy từ gợi ý `BE-P5-E03`. User xác nhận mới tạo giao dịch. Nơi chạy nhận dạng và việc có giữ ảnh hay không theo ADR của `PRD-P8-E01`; nếu giữ ảnh thì file ở object storage, database chỉ giữ metadata, ảnh có trong xuất dữ liệu và bị xóa cùng tài khoản. Cờ `ocr` tắt thì nút Scan không hiện. Đo tỷ lệ nhận đúng (spec §54 "OCR success rate") và có nút báo "Không đúng". Thiết kế qua task `DS` trước khi code.
- Note: chuyển từ `BE-P5-E02` / `MOB-P5-E02` ngày 2026-11-11.

### BE-P8-E03 / MOB-P8-E03 — Ask Freeva
- Status: todo
- Module: 18
- Gate: post-v1
- Depends: BE-P1-007, BE-P5-E08, PRD-P8-E01, PRD-P8-E02
- DoD: mọi số trong câu trả lời đến từ Finance Query đã có. Model không tự cộng trừ và không dùng bộ nhớ chat làm nguồn số. Thiếu dữ liệu thì nói thiếu. Không tạo giao dịch, không sửa ngân sách, mục tiêu hoặc chuyển tiền. Có bộ câu hỏi đánh giá trước khi bật. Thời gian giữ hội thoại ghi trong privacy policy. Cờ `ai_chat`. Nút báo "Không đúng" trên từng câu trả lời.
- Note: chuyển từ `BE-P5-E05` / `MOB-P5-E05` ngày 2026-11-11.
