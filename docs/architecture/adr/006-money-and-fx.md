# ADR 006 — Money and FX

- **Status:** accepted
- **Date:** 2026-08-26

## Decision

- Lưu số tiền bằng **integer minor units** (VND: 1 = 1 đồng). Không `FLOAT`/`DOUBLE`.
- API JSON: `{ "amountMinor": "150000", "currency": "VND" }` (string integer để an toàn JS).
- Transfer: hai bản ghi linked, tổng nguồn + đích = 0 theo từng currency (hoặc cặp FX đã chốt).
- MVP: FX nhập tay, lưu `rate` + `quotedAt`. Không auto-FX cho đến khi có nguồn tin cậy.
- Múi giờ user (`Asia/Ho_Chi_Minh` mặc định). `occurredOn` = calendar date theo TZ user.

## Consequences

Mọi report/test so sánh số nguyên. Helper money có unit test (`QA-P0-*`). Cấu trúc bảng: [ADR 007](007-core-data-model.md).
