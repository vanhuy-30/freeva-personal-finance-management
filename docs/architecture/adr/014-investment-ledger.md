# ADR 014 — Investment ledger

- **Status:** accepted
- **Date:** 2026-11-06
- **Task:** `BE-P4-E01`

## Decision

**Vị thế tách khỏi ví.** `Investment` là một khoản theo dõi riêng (vàng, cổ phiếu, chứng chỉ quỹ, tiền gửi tiết kiệm, bất động sản, crypto). Số dư ví không bao giờ chứa giá trị khoản đầu tư.

**Chuyển ví ↔ đầu tư là giao dịch một chân loại `investment`** (`TransactionType.investment`, additive), giống `debt` ([personal-debts](../personal-debts.md)):

| Thao tác | Chân ví | Vị thế |
|---|---|---|
| Mua / góp thêm | âm (tiền ra ví) | cộng số lượng, cộng giá vốn |
| Bán / rút | dương (tiền về ví) | trừ số lượng, trừ giá vốn phần bán |

Giao dịch `investment` **không** vào thu/chi, ngân sách, tỷ lệ tiết kiệm; có trong số dư ví, lịch sử, export. `PATCH`/`DELETE /transactions/{id}` trên chân này bị chặn (400) để vị thế không lệch.

**Số.** Tiền là `bigint` minor units. Số lượng là `Decimal(28,8)` ở DB và chuỗi thập phân trên API; mọi phép tính dùng số nguyên có hệ số `10^8`, không `double`. Giá nhập tay là tiền trên **một đơn vị** (một chỉ, một cổ phiếu, một coin).

**Giá vốn bình quân gia quyền.** `costBasisMinor` là tổng tiền đã bỏ vào phần đang giữ.

- Mua `q` với `amount`: `quantity += q`, `costBasis += amount`.
- Bán `q` (≤ `quantity`) với `proceeds`: phần giá vốn bị trừ `removed = round_half_up(costBasis × q / quantity)`; bán hết thì `removed = costBasis`. `realized = proceeds − removed`. Bán quá số lượng → `INVESTMENT_OVERSELL` (422), không cắt ngầm.
- `realized` lưu trên từng lần bán, chỉ hiện ở màn đầu tư.

**Giá trị hiện tại** = `round_half_up(quantity × priceMinor)` với giá nhập gần nhất theo `quotedAt`. Chưa có giá → giá trị `null`, tài sản ròng dùng giá vốn và đánh dấu `valuation = cost`. Lãi/lỗ chưa thực hiện = giá trị − giá vốn (chỉ khi có giá). Giá lưu `source = manual` và `quotedAt`; màn hình hiện ngày cập nhật. Không có API giá tự động ở v1.

**Tiền gửi tiết kiệm.** Số lượng cố định `1`, giá vốn là gốc, một lần gửi duy nhất (gửi thêm → `INVESTMENT_UNSUPPORTED`; làm sau nếu cần). Lãi đơn: `interest = round_half_up(principal × rateBps × days / (10000 × 365))`, `days` = từ ngày gửi tới `min(hôm nay, ngày đáo hạn)`. Giá trị hiện tại = gốc + lãi đó. Rút phải rút hết (`quantity = 1`); tiền về trừ giá vốn là lãi thực hiện.

**Đơn vị vàng.** Số lượng lưu theo đơn vị người dùng chọn (`chi` hoặc `luong`); 1 lượng = 10 chỉ. Giá nhập cùng đơn vị đó; hai đơn vị không trộn trong một khoản.

**Tránh tính trùng.** Tài sản ròng = ví tiền (đã trừ phần chuyển đi) + giá trị đầu tư + phải thu − nợ. Vì chân `investment` đã rút tiền khỏi ví nên cộng giá trị vị thế không trùng. Khoản đã lưu trữ không tính. Chỉ lưu trữ khi `quantity = 0`.

**Không lời khuyên.** Không tự mua, bán, gợi ý.

## Consequences

- Migration additive: `ALTER TYPE "TransactionType" ADD VALUE 'investment'` + 3 bảng; deploy migration trước API.
- Báo cáo và `GET /transactions` loại `investment` khỏi thu/chi như `debt`.
- Export và xóa tài khoản phải gồm bảng mới.
- Bảng số chuẩn (vàng chỉ/lượng, crypto lẻ, mua → góp → bán một phần, lãi tiền gửi) nằm trong test domain và là nền của `QA-P4-E01`.
- Tài sản ròng theo thời gian (`BE-P4-E02`) dựng trên cùng các số này.
