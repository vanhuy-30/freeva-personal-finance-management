# Phase 6 — epic

[phase-06.md](../docs/product/phases/phase-06.md)

Điều kiện tiên quyết: DPA đối tác, chống trùng ổn, threat model RBAC. Không thuộc product v1.

### BE-P6-E01 / MOB-P6-E01 — Kết nối ngân hàng qua đối tác (module 13 API)
- Status: todo
- Module: 13
- Gate: post-v1
- Depends: BE-P5-E08, SEC-P6-E01
- DoD: đồng bộ không ghi đè giao dịch sửa tay. Mỗi dòng có nguồn. Ngắt kết nối thì thu hồi hoặc xóa token đối tác. Cờ `bank_connect` tắt thì không hiện lối kết nối. Lỗi đối tác có runbook.
- Note: 2026-11-11 bỏ phụ thuộc `BE-P5-E01` (nhập sao kê file không làm). Chống trùng dùng lại quy tắc của `BE-P3-011`.

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

### SEC-P6-002 — Rà soát test sâu và vá bảo mật trước store
- Status: done
- Module: 22
- Gate: v1
- Depends: SEC-P1-001
- DoD: chạy những gì CI không chạy (integration local, thứ tự ngẫu nhiên, nhiều múi giờ, drift Prisma, audit dependency, test web-admin). Lỗi tìm được có test tái hiện. Rate limit auth đúng IP client sau proxy. Xóa và xuất toàn bộ tài khoản phải nhập lại mật khẩu (tài khoản chỉ OAuth: phiên ≤ 10 phút). Web admin có header chống clickjacking. Dependency vá trong cùng major.
- Verification: xem [security-test-phase1.md](../docs/architecture/security-test-phase1.md#đợt-rà-soát-sec-p6-002).
- Note: `POST /v1/account/export` thay `GET`; app build cũ không xuất/xóa được tài khoản cho tới khi cập nhật (staging). Render đặt `TRUST_PROXY_HOPS=1`; số hop thật cần kiểm trên staging.
- Tồn đọng (task riêng khi cần):
  - Staff dùng chung một token và web admin không có đăng nhập: audit không phân biệt người, không thu hồi riêng.
  - Rate limit 5 lần/email: người khác có thể khóa đăng nhập của một email.
  - Đăng nhập không bắt email đã xác minh: có thể đăng ký trước email của người khác.
  - Android release còn ký bằng debug key; iOS `aps-environment` = development.
  - `deepmerge-ts` 7 (Prisma 6), `glob`/`minimatch` trong tooling build của `@sentry/nextjs` cần major mới.
