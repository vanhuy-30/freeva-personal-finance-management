# Phase 1 — Ghi chép tài chính cốt lõi

Đây là gate sổ cái, chưa phải product v1. Xem [spec-alignment.md](../spec-alignment.md).

Người dùng bắt đầu trong vài phút, ghi thu chi, thấy bức tranh đáng tin.

**Bắt buộc:** module 1, 2, 3, 4, 5, 14, 19, 20 MVP, 21–22 phát hành, 24–25 tối thiểu.

**Hoãn được:** avatar, nhãn, sửa hàng loạt, ảnh hóa đơn, offline đầy đủ, FX tự động.

## Điều kiện hoàn thành

- Onboarding → ví → giao dịch đầu không cần hỗ trợ.
- Số dư đúng sau thu/chi/chuyển/sửa/xóa.
- Sync không tạo trùng ở kịch bản chính.
- Báo cáo khớp nguồn.
- Export, xóa TK, reset password, thu hồi phiên hoạt động.

## Đóng phase (2026-10-21)

Phase 1 **closed** (gate sổ cái). Backlog 28/28 done, gồm `Gate: v1` và Should (merchant/nhãn, offline queue, OAuth backend, …). Residual vận hành (deploy staging, E2E native/Resend, DSN Sentry, nút OAuth mobile) chấp nhận — không chặn mở Phase 2. Chưa phải product v1. Chi tiết: [STATUS](../../project-state/STATUS.md).

Backlog: [tasks/phase-01.md](../../../tasks/phase-01.md).
