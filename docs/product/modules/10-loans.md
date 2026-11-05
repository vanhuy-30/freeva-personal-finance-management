# Module 10 — Khoản vay và công nợ

- **Phase:** 3 — cho mượn / đi mượn bản nhẹ `BE-P3-007` (`Gate: v1`); vay có lãi `BE-P3-E02` sau v1
- **Prefix:** `BE`, `MOB`, `QA`

Vay / cho vay. Gốc, lãi, kỳ hạn. Công thức lãi có bộ test chuẩn. Lịch trả, gốc/lãi, quá hạn, tổng lãi dự kiến.

## Quyết định BE-P3-007 (2026-11-02)

- Cho mượn / đi mượn người quen là bảng riêng `PersonalDebt`, không lãi. Tiền di chuyển bằng giao dịch `debt` một chân, không tính thu/chi, ngân sách; phải thu cộng tài sản, phải trả cộng nợ trong tài sản ròng. Chi tiết: [personal-debts.md](../../architecture/personal-debts.md).

## Quyết định BE-P3-E02 (2026-11-02)

- Lãi tính trên dư nợ giảm dần, số nguyên, làm tròn half-up; lịch trả kiểu kỳ cố định hoặc theo số tiền user nhập. Chi tiết: [loans.md](../../architecture/loans.md).
- Mỗi lần trả: phần gốc là giao dịch `debt` (giảm nợ, không tính chi tiêu), phần lãi là một khoản chi (danh mục "Lãi vay").
