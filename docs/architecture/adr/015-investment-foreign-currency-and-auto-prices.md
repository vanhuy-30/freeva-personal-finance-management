# ADR 015 — Đầu tư ngoại tệ và giá / tỷ giá tự động

- **Status:** proposed — chưa quyết, chờ chủ dự án chốt các câu hỏi bên dưới
- **Date:** 2026-11-27
- **Task:** `BE-P4-E04` / `MOB-P4-E04` (giá, tỷ giá tự động), `BE-P4-E05` (đầu tư ngoại tệ); cả hai `todo`, `Gate: post-v1`

Không có code trong ADR này. Nó ghi hiện trạng, hai việc tách riêng, các phương án và những quyết định cần chủ dự án chốt trước khi làm.

## Bối cảnh

Quyết định đang có (v1):

- Giá khoản đầu tư **chỉ nhập tay**, kèm nguồn (`manual` hoặc `trade`) và ngày ([ADR 014](014-investment-ledger.md); module 12: "không giả realtime").
- Tỷ giá hiển thị **chỉ do người dùng nhập** (`UserFxRate`, [ADR 006](006-money-and-fx.md)); chỉ để hiển thị, không chạm sổ cái. Không tự lấy tỷ giá khi chưa có nguồn tin cậy.
- **Vị thế luôn cùng tiền tệ với ví mua/bán** (chốt 2026-11-09, `QA-P4-E01`); API trả 400 nếu khác. "Đã sở hữu" dùng tiền tệ hồ sơ.
- `DECISIONS-OPEN` #6 "Nguồn FX / giá / bank": "FX tay ở MVP; partner Phase 6", đang mở.

Hạ tầng đã có sẵn: `Investment.currencyCode`, `InvestmentPrice(source, quotedAt)`, `FxQuoteSource.provider` (chưa dùng), tài sản ròng đã quy đổi để hiển thị bằng `UserFxRate` cho vị thế ngoại tệ nằm trong ví ngoại tệ. Chưa có: scheduler, client HTTP giá, bảng giá dùng chung, mã chứng khoán/ticker.

## Việc 1 — Vị thế và giá ngoại tệ (`BE-P4-E05`)

Đảo quyết định 2026-11-09, nên cần ADR chốt. Hai mô hình sổ cái:

| | A. Vị thế có tiền tệ riêng | B. Báo giá ngoại tệ, sổ cái theo tiền tệ ví/hồ sơ |
|---|---|---|
| Ý | Vị thế ghi bằng tiền tệ của nó; mua từ ví khác tiền tệ thì kèm tỷ giá (như chuyển khoản, `FxQuote`) | Vị thế vẫn cùng tiền tệ ví; chỉ giá được báo bằng ngoại tệ rồi quy đổi |
| Giá vốn | Theo tiền tệ vị thế, thấy lãi/lỗ tỷ giá | Theo tiền tệ ví, lãi/lỗ tỷ giá bị ẩn |
| Schema (additive) | tỷ giá + `quotedAt` + nguồn trên lần mua/bán | `InvestmentPrice` thêm `currencyCode` và tỷ giá |
| Độ khó | Lớn: bỏ kiểm tra `walletFor`, đổi tính lãi/lỗ thực hiện, báo cáo, lịch sử | Vừa |
| Rủi ro | Cao ở sổ cái và test | Thấp hơn, nhưng số hiển thị che mất phần tỷ giá |

Phạm vi tác động chung: `investmentRows` và `investmentHistory` (báo cáo, tài sản ròng theo thời gian chưa quy đổi), form mua/bán/giá trên mobile, bỏ chọn một tiền tệ ở tổng hợp, `QA-P4-E01` thêm dòng tỷ giá.

## Việc 2 — Giá và tỷ giá tự động (`BE-P4-E04`)

Backend chưa có thành phần nào: không `@nestjs/schedule`, không client giá. Mẫu có thể theo: worker chạy theo chu kỳ (`recurring.worker`, `notification.worker`), nhà cung cấp ngoài tắt khi thiếu biến môi trường (FCM, [ADR 013](013-fcm-push.md)).

Cần: module `FxProvider` / `PriceProvider` (adapter mỗi nguồn: tỷ giá, vàng trong nước, cổ phiếu/quỹ, crypto; timeout, thử lại, cache); bảng giá **dùng chung** (không theo người dùng) với nguồn, `quotedAt`, `fetchedAt`; vị thế cần mã (`symbol`/ticker) để khớp giá; `InvestmentPrice.source` thêm giá trị `auto`; `UserFxRate` thêm nguồn; cờ và cấu hình ở server (theo quyết định #13: bật/tắt, chu kỳ, ngưỡng cũ); giao diện hiện nguồn, thời điểm và cảnh báo giá cũ, và cho ghi đè bằng tay.

Hướng làm theo bậc (rẻ và ít rủi ro trước): tỷ giá tự động (nguồn chuẩn, nuôi sẵn `RateBook`), rồi crypto, cuối cùng vàng và chứng khoán Việt Nam (nguồn riêng lẻ, điều khoản sử dụng khó). Ngoài code còn: giấy phép/ToS của nhà cung cấp, chi phí, giám sát, runbook, rà soát quyền riêng tư (không gửi dữ liệu người dùng cho nhà cung cấp).

## Câu hỏi cần chủ dự án chốt

1. Có làm đầu tư ngoại tệ ở v1.x không, hay giữ quyết định 2026-11-09?
2. Mô hình sổ cái: A (vị thế tiền tệ riêng + tỷ giá lúc mua) hay B (báo giá ngoại tệ, quy đổi về tiền tệ ví)?
3. Lãi/lỗ do tỷ giá: gộp vào lãi/lỗ vị thế hay hiện riêng?
4. Nguồn tỷ giá, giá vàng, cổ phiếu/quỹ, crypto: dùng nhà cung cấp nào, ai trả phí, làm trước Phase 6 hay cùng?
5. Giá nhập tay luôn thắng giá tự động, hay giá mới hơn thắng? Bao lâu thì coi giá là cũ và báo?
6. Giá/tỷ giá tự động có được tự đổi tài sản ròng, hay chỉ hiện như gợi ý để người dùng xác nhận?
7. Tỷ giá của một lần mua có đóng băng (snapshot như chuyển khoản) hay định giá lại theo thời gian?
8. Người dùng đã nhập tỷ giá tay thì tự động có đè lên không?

## Hệ quả khi chốt

Cập nhật ADR 006 (không tự lấy tỷ giá khi chưa có nguồn) và ADR 014 (không có API giá tự động ở v1), module 12, `investments.md`, `QA-P4-E01`, và mở task theo từng bậc nguồn giá.
