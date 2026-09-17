# Phase 0 — Nền tảng và kiểm chứng sản phẩm

## Mục tiêu

Giảm rủi ro kỹ thuật và pháp lý trước nghiệp vụ. Thống nhất mô hình dữ liệu cho đa tiền tệ, chuyển khoản, đồng bộ, báo cáo.

## Phạm vi

- Persona, thị trường VN, use case ưu tiên.
- Data model: user, ví, giao dịch, danh mục, tiền tệ, FX.
- Biểu diễn tiền, timezone, ngày tài chính, transfer, soft-delete.
- Design system, navigation, analytics, feature flag.
- Env: local / test / staging / prod + quy trình phát hành.
- Module 20 (nền), 21, 22, 26 tối thiểu.
- Bảng chuẩn transfer cân bằng (chưa ledger): [transfer-balance-test-cases.md](../../architecture/transfer-balance-test-cases.md).

## Chưa làm

Dashboard admin đầy đủ, báo cáo kinh doanh, CSKH, ngân hàng, AI, đầu tư tự động.

## Điều kiện hoàn thành

- Data model + security flow được review.
- Prototype vòng ghi thu chi với user mục tiêu (sau scaffold: chưa bắt buộc xong trong lần foundation này).
- Staging, logging, crash, backup/restore đã thử (local compose + runbook là bước đầu).
- Danh sách tuân thủ thị trường đầu (PDPD) — xem architecture.

Backlog: [tasks/phase-00.md](../../../tasks/phase-00.md).
