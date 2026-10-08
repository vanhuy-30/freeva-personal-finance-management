# Phase 6 — epic

[phase-06.md](../docs/product/phases/phase-06.md)

Điều kiện tiên quyết: DPA đối tác, chống trùng ổn, threat model RBAC. Không thuộc product v1.

### BE-P6-E01 / MOB-P6-E01 — Kết nối ngân hàng qua đối tác (module 13 API)
- Status: todo
- Module: 13
- Gate: post-v1
- Depends: BE-P5-E01, BE-P5-E08, SEC-P6-E01
- DoD: đồng bộ không ghi đè giao dịch sửa tay. Mỗi dòng có nguồn. Ngắt kết nối thì thu hồi hoặc xóa token đối tác. Cờ `bank_import` tắt thì không hiện lối kết nối. Lỗi đối tác có runbook.

### BE-P6-E02 / MOB-P6-E02 — Gia đình và chia sẻ (module 16)
- Status: todo
- Module: 16
- Gate: post-v1
- Depends: SEC-P6-E01, BE-P5-E08
- DoD: ma trận quyền ghi rõ ví nào được chia sẻ. Ví không chia sẻ không xuất hiện với thành viên khác. Cờ `family`. Mời và rời nhóm có audit.

### SEC-P6-E01 — Token đối tác, xung đột nhiều người, audit
- Status: todo
- Module: 22, 16, 13
- Gate: post-v1
- Depends: SEC-P0-001
- DoD: threat model cập nhật cho token đối tác và hai người sửa cùng một sổ. Audit gắn actor. Không log số dư trong payload đối tác.
