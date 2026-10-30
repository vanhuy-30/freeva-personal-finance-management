# ADR 006 — Money and FX

- **Status:** accepted
- **Date:** 2026-08-26

## Decision

- Lưu số tiền bằng **integer minor units** (VND: 1 = 1 đồng). Không `FLOAT`/`DOUBLE`.
- API JSON: `{ "amountMinor": "150000", "currency": "VND" }` (string integer để an toàn JS).
- Transfer: hai bản ghi linked, tổng nguồn + đích = 0 theo từng currency (hoặc cặp FX đã chốt).
- MVP: FX nhập tay, lưu `rate` + `quotedAt`. Không auto-FX cho đến khi có nguồn tin cậy.
- **Ngoại lệ chỉ hiển thị (`BE-P2-013`):** Tổng quan, chi tiết ví và chi tiết giao dịch có thể hiện số quy về một tiền tệ khác bằng tỷ giá người dùng nhập (`UserFxRate`, một dòng mỗi chiều, không nghịch đảo). Số quy đổi không bao giờ được ghi vào sổ cái hay số dư, và không phải nguồn của báo cáo kỳ. Chỉ cộng vào tổng khi đổi đúng minor unit; thiếu tỷ giá hoặc lệch lẻ thì dòng gốc giữ nguyên và nằm ngoài tổng (`unconverted`). Báo cáo kỳ (`byCategory`, `byAccount`, so sánh, xu hướng) vẫn tách từng loại tiền.
- Múi giờ user (`Asia/Ho_Chi_Minh` mặc định). `occurredOn` = calendar date theo TZ user.

## Consequences

Mọi report/test so sánh số nguyên. Helper money có unit test (`QA-P0-*`); bảng chuẩn transfer: [transfer-balance-test-cases.md](../transfer-balance-test-cases.md). Cấu trúc bảng: [ADR 007](007-core-data-model.md).
