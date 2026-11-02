# Module 10 — Khoản vay và công nợ

- **Phase:** 3 — cho mượn / đi mượn bản nhẹ `BE-P3-007` (`Gate: v1`); vay có lãi `BE-P3-E02` sau v1
- **Prefix:** `BE`, `MOB`, `QA`

Vay / cho vay. Gốc, lãi, kỳ hạn. Công thức lãi có bộ test chuẩn. Lịch trả, gốc/lãi, quá hạn, tổng lãi dự kiến.

## Quyết định BE-P3-E02 (2026-11-02)

- Lãi tính trên dư nợ giảm dần, số nguyên, làm tròn half-up; lịch trả kiểu kỳ cố định hoặc theo số tiền user nhập. Chi tiết: [loans.md](../../architecture/loans.md).
- Mỗi lần trả = hai giao dịch expense (phần gốc, phần lãi), tính vào báo cáo chi tiêu. Tách gốc khỏi chi tiêu là việc sau.
