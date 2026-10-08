# Phase 7 — epic

[phase-07.md](../docs/product/phases/phase-07.md). Không thuộc product v1.

### BE-P7-E01 / MOB-P7-E01 — Subscription và entitlement (module 23)
- Status: todo
- Module: 23
- Gate: post-v1
- Depends: BE-P5-E04, BE-P5-E08
- DoD: Free gồm ghi thu chi, ví, danh mục, ngân sách cơ bản, báo cáo cơ bản. Premium gồm insight, chat, OCR, báo cáo mở rộng, forecast, what-if, mục tiêu nâng cao và định kỳ không giới hạn. Hết hạn hoặc hạ cấp không xóa dữ liệu và không khóa xem sổ cũ. Entitlement giống nhau trên các thiết bị. Khôi phục giao dịch mua. Paywall không chặn tạo ví, ghi giao dịch, xem số dư, xuất hoặc xóa tài khoản.

### WA-P7-E01 / BE-P7-E02 — Admin vận hành (module 26)
- Status: todo
- Module: 26
- Gate: post-v1
- Depends: WA-P0-002, INF-P1-001
- DoD: số user, user hoạt động, user mới, số giao dịch, số request AI, số request OCR, tỷ lệ crash. Tra cứu tài khoản theo trạng thái, khóa, xóa, gói. Màn hình mặc định không có số dư, giao dịch hay ghi chú. Mở dữ liệu tài chính để hỗ trợ là quyền riêng, có audit, tắt mặc định.

### WA-P7-E02 / MOB-P7-E02 — Support mở rộng (module 25)
- Status: todo
- Module: 25
- Gate: post-v1
- Depends: WA-P7-E01
- DoD: hàng đợi hỗ trợ có vai trò, SLA và audit. Nhân viên không xem dữ liệu tài chính trừ khi quyền ở `WA-P7-E01` được bật cho ca đó.
