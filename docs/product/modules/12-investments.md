# Module 12 — Tài sản và đầu tư

- **Phase:** 4 — `Gate: v1` từ 2026-11-02 (`BE-P4-E01`, `BE-P4-E02`, `QA-P4-E01`)
- **Prefix:** `BE`, `MOB`

**v1 (chốt 2026-11-02):** vàng, cổ phiếu, chứng chỉ quỹ, tiền gửi tiết kiệm, bất động sản, crypto. Giá nhập tay, hiện nguồn và ngày cập nhật — không giả realtime. API giá tự động làm sau.

**Ghi sổ:** mua hoặc góp thêm = chuyển từ ví sang khoản đầu tư, cộng vào giá vốn; không phải chi tiêu. Bán hoặc rút = chuyển về ví; chênh lệch so với giá vốn là lãi/lỗ thực hiện, chỉ hiện trong màn đầu tư (không vào báo cáo thu chi, chốt 2026-11-02). Giá trị hiện tại = số lượng × giá nhập gần nhất (tiền gửi: gốc + lãi tới hôm nay; bất động sản: giá trị ước tính nhập tay); chênh với giá vốn là lãi/lỗ chưa thực hiện. Tài sản ròng = ví tiền + đầu tư − nợ, không tính trùng phần tiền đã chuyển.

Chỉ theo dõi: không mua bán, không lời khuyên. Tiền gửi có kỳ hạn (module 11 cũ) là một loại ở đây.

Kiến trúc và công thức: [investments.md](../../architecture/investments.md), [ADR 014](../../architecture/adr/014-investment-ledger.md).
