# Tài sản và đầu tư — BE-P4-E01

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/investments`. Module: [12-investments](../product/modules/12-investments.md). Quyết định ghi sổ: [ADR 014](adr/014-investment-ledger.md). Phần mobile (`MOB-P4-E01`) chưa làm.

## Mô hình

- `Investment`: loại (`gold` · `stock` · `fund` · `savings_deposit` · `real_estate` · `crypto`), tên (≤ 80), tiền tệ, đơn vị (`chi`/`luong` cho vàng, `share`, `unit`, `coin`, `deposit`, `property`), **số lượng** (`Decimal(28,8)`), **giá vốn** (`costBasisMinor`, bình quân gia quyền của phần đang giữ), tiền gửi có `interestRateBps` + `startDate` + `maturityDate`, ghi chú, `archivedAt`, `version`.
- `InvestmentTrade`: một lần mua hoặc bán, số lượng, tiền, ví, `clientId` idempotent, `transactionClientId` của chân ví, `realizedMinor` (chỉ khi bán).
- `InvestmentPrice`: giá một đơn vị nhập tay, `source = manual`, `quotedAt`.

## Tiền đi đâu

Mỗi lần mua/bán là **một** giao dịch `investment` một chân trên ví (`TransactionType.investment`, migration `20261106100000_investments`, additive; deploy trước API), cùng commit với vị thế. Không phải thu hay chi: không vào báo cáo thu/chi, ngân sách, tỷ lệ tiết kiệm; có trong số dư ví, lịch sử, export. `PATCH`/`DELETE /transactions/{id}` trên chân này → 400. `GET /reports/...` `byAccount` có thêm `investmentMinor` (âm = mua, dương = bán) và `netMinor` đã gồm nó.

| Thao tác | Chân ví | Vị thế | Audit |
|---|---|---|---|
| tạo vị thế | không | số lượng 0 | `investment.create` |
| mua / góp thêm | âm | `+quantity`, `+cost` | không |
| bán / rút | dương | `−quantity`, `−cost` phần bán | không |
| nhập giá | không | không đổi số lượng | không |

## Công thức

Số nguyên, không `double`. Số lượng là số nguyên hệ số `10^8` trong code.

- Giá vốn phần bán: `removed = round_half_up(costBasis × sold / held)`; bán hết thì `removed = costBasis`. `realized = proceeds − removed`.
- Giá trị hiện tại: `round_half_up(quantity × priceMinor)` với giá `quotedAt` mới nhất. Chưa có giá → giá trị = giá vốn, `valuationBasis = cost`, `unrealizedMinor = null`.
- Tiền gửi: `interest = round_half_up(principal × rateBps × days / (10000 × 365))`, `days` từ ngày gửi tới `min(hôm nay, đáo hạn)`. Giá trị = gốc + lãi. 100tr · 12%/năm · 365 ngày → 12tr.
- Vàng: 1 lượng = 10 chỉ; mỗi vị thế dùng một đơn vị, giá nhập theo đúng đơn vị đó.

Ví dụ chuẩn (có trong test): mua 10 chỉ giá 70tr, góp 5 chỉ giá 37,5tr → 15 chỉ, giá vốn 107,5tr; bán 6 chỉ thu 48tr → giá vốn trừ 43tr, lãi thực hiện 5tr, còn 9 chỉ, giá vốn 64,5tr.

## Quy tắc

- Ví phải cùng tiền tệ với vị thế. Bán quá số lượng → `INVESTMENT_OVERSELL` (422), không cắt ngầm.
- `savings_deposit` và `real_estate` giữ đúng một món: số lượng phải là 1, chỉ một lần mua (lần hai → `INVESTMENT_UNSUPPORTED`), bán là bán hết. Tiền gửi không nhận giá nhập.
- Lưu trữ chỉ khi số lượng 0 (`INVESTMENT_CONFLICT`), nếu không vị thế biến khỏi tài sản ròng trong khi ví đã trả tiền.
- Retry cùng `clientId` trả kết quả cũ (200); khác nội dung → 409. Id chân giao dịch sinh cố định từ `clientId`.

## Tài sản ròng

`GET /reports/net-worth` cộng giá trị hiện tại của vị thế đang giữ vào `assetsMinor` theo tiền tệ. Chân `investment` đã rút tiền khỏi ví nên không tính trùng: ví 100tr, mua 5 chỉ giá vốn 35tr, giá hiện tại 8tr/chỉ → 65tr + 40tr = 105tr.

## API

Bearer session, `Cache-Control: no-store`, tiền là string integer, số lượng là string thập phân. `GET/POST /investments`, `GET/PATCH/DELETE /investments/{id}` (DELETE cần `version`), `GET /investments/summary` (giá vốn, giá trị, lãi/lỗ chưa thực hiện, số khoản chưa có giá theo tiền tệ), `GET/POST /investments/{id}/trades`, `GET/POST /investments/{id}/prices`. Có trong `GET /account/export` (`investments`, `investmentTrades`, `investmentPrices`) và xoá theo user. Không log số tiền hay số lượng.

## Chưa làm

Giá tự động; gửi thêm vào tiền gửi; vị thế khác tiền tệ ví với tỷ giá; biểu đồ tài sản ròng theo thời gian (`BE-P4-E02`); mobile (`MOB-P4-E01`, cần thêm `TransactionType.investment` vào app trước khi hiện chân này).
