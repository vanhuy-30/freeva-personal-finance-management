# Dự báo số dư theo quy tắc — BE-P3-E04

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `GET /api/v1/forecast`. Module: [14-reports](../product/modules/14-reports.md), [15-calendar](../product/modules/15-calendar.md). Không gọi model; forecast AI là `BE-P5-E06`.

## Cách tính

Từ hôm nay (timezone hồ sơ) đến hết tháng thứ `months` (1–12, mặc định 3, tính cả tháng hiện tại):

- **Số dư gốc**: tổng `initialBalanceMinor` + giao dịch chưa xóa của ví không lưu trữ, không phải thẻ tín dụng, cùng `currencyCode` (mặc định tiền tệ hồ sơ). Ghi đè bằng `startingBalanceMinor`.
- **Dòng tiền**: rule `income` / `expense` đang bật (cả định kỳ tự chạy lẫn hóa đơn nhắc), chiếu bằng `occurrencesInRange` (kẹp ngày 31, dừng ở `endDate`). Chuyển khoản, điều chỉnh, nợ không tính.
- Mỗi tháng: `opening + income + expense = closing`; `closing` là `opening` tháng sau. Chi là số âm. Tiền là string minor units.
- Bỏ khoản: `excludeRuleIds` (cách nhau dấu phẩy).

## Giả định (`assumptions`)

`balanceSource` (`wallets` | `user`), `includesCreditWallets=false`, `includesOneOffSpending=false`, `includedRuleIds`, `excludedRuleIds`, `otherCurrencyRuleIds` (rule khác loại tiền, không quy đổi FX). Mobile dùng để hiện giả định và cho sửa input.

Bearer session, `Cache-Control: no-store`. Không log số tiền, tên hóa đơn.
