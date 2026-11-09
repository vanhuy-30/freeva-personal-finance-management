# Phase 4 — epic

[phase-04.md](../docs/product/phases/phase-04.md). Theo dõi tài sản/đầu tư và tài sản ròng theo thời gian là `Gate: v1` từ 2026-11-02 (quyết định chủ dự án).

### BE-P4-E01 / MOB-P4-E01 — Tài sản và đầu tư (module 12)
- Status: done — BE xong 2026-11-06, thiết kế chốt 2026-11-06, API theo thiết kế xong 2026-11-06 (`BE-P4-E03`), MOB xong 2026-11-07 (5 PR)
- Module: 12
- Gate: v1
- Depends: BE-P1-004, BE-P1-007
- DoD: sáu loại tài sản: vàng (chỉ, lượng), cổ phiếu, chứng chỉ quỹ, tiền gửi tiết kiệm (kỳ hạn, lãi suất, ngày đáo hạn; thay module 11), bất động sản, crypto. Vị thế tách khỏi số dư ví tiền. Mua hoặc góp thêm là chuyển tiền từ một ví sang khoản đầu tư và cộng vào giá vốn (gốc), không ghi chi tiêu, không tính ngân sách và báo cáo thu chi. Bán hoặc rút là chuyển về ví; lãi/lỗ thực hiện = tiền về trừ phần giá vốn tương ứng, chỉ hiện trong màn đầu tư, không tính vào thu/chi, ngân sách hay tỷ lệ tiết kiệm. Số lượng là Decimal (crypto tới 8 chữ số thập phân), tiền vẫn minor units. Giá v1 nhập tay, lưu kèm nguồn `manual` và thời điểm; màn hình hiện ngày cập nhật giá. API giá tự động làm sau. ADR chốt cách ghi sổ (giá vốn, lãi/lỗ, chuyển ví ↔ đầu tư) trước khi code. Không tự mua, bán hoặc đưa lời khuyên. Cờ `investment` làm sau cùng `BE-P5-E08`; tới lúc đó module luôn hiện.
- Note: BE-P4-E01 xong 2026-11-06: ADR [014](../docs/architecture/adr/014-investment-ledger.md), `/api/v1/investments` (CRUD, `summary`, `trades` mua/bán idempotent, `prices` nhập tay), chuyển ví ↔ đầu tư bằng giao dịch `investment` một chân (ngoài thu/chi, ngân sách, tỷ lệ tiết kiệm; khoá sửa/xoá), giá vốn bình quân gia quyền, lãi/lỗ thực hiện trên từng lần bán, tiền gửi lãi đơn tới đáo hạn, giá trị vào `/reports/net-worth` không tính trùng ví, `byAccount.investmentMinor`, audit `investment.create`, OpenAPI, export/xoá tài khoản. Chưa có: gửi thêm vào tiền gửi, vị thế khác tiền tệ ví (tỷ giá), mobile. Kiến trúc: [investments.md](../docs/architecture/investments.md). `MOB-P4-E01` phải thêm `TransactionType.investment` vào app trước khi hiện chân này.
- Note: MOB PR 1/4 xong 2026-11-07: `TransactionType.investment` (chân ví khoá sửa/xoá), `/me/investments` (P.1, P.2: thẻ tổng, tỷ trọng, danh mục, chưa giá), ô "Đầu tư" ở lưới Cá nhân, dòng Đầu tư ở Tài sản ròng mở màn này. Còn: tạo (P.5, P.6), danh mục/tài sản/bán/giá/tiền gửi (P.3, P.9–P.12), chi tiết/sửa/xoá lần mua (P.4, P.7, P.8), `pairs.py` nhóm `P`. [Mobile](../docs/architecture/mobile-investments.md).
- Note: MOB PR 5/5 xong 2026-11-07: chi tiết lần mua (P.4), sửa (P.7), xoá có sheet xác nhận (P.8), `pairs.py` nhóm `P`. Không còn gap so với DoD của MOB; chưa có: footer "Đã bán hết" và xem lại từng lần bán (ngoài thiết kế đã chốt), FX khác tiền tệ ví (`QA-P4-E01`).
- Note: MOB PR 4/5 xong 2026-11-07: tiền gửi `/me/investments/:id` (P.11), rút tiền gửi (P.12, bán số lượng 1 với số tiền nhận), sửa khoản (`PATCH`), xoá khoản (xoá lần mua duy nhất), danh mục Tiền gửi liệt kê nhiều khoản. Còn: P.4, P.7, P.8, `pairs.py` nhóm `P`.
- Note: MOB PR 3/5 xong 2026-11-07: `/me/investments/kind/:kind` (P.3), bán (P.9) với lãi chốt xem trước, cập nhật giá (P.10), Mua thêm qua form tạo, dòng "Đã bán". Còn: tiền gửi P.11/P.12, lần mua P.4/P.7/P.8, `pairs.py` nhóm `P`.
- Note: MOB PR 2/5 xong 2026-11-07: `/me/investments/new` (P.5 sáu danh mục, vàng chỉ/lượng, P.6 tiền gửi), số lượng Decimal 8 chữ số (`core/money/quantity.dart`), chọn ví hoặc "đã có từ trước", `POST /investments` kèm lần mua đầu. Còn: P.3, P.9–P.12, P.4, P.7, P.8.
- Note: MOB theo board P.1–P.12 ([P-investments.md](../docs/brand/patterns/P-investments.md)): danh mục → tài sản → lần mua; Mua thêm, Bán, Cập nhật giá ở tài sản; lần mua chỉ xem, sửa, xoá; thêm ô Đầu tư vào lưới Cá nhân; thêm nhóm `P` vào `apps/mobile/tool/design_compare/pairs.py` khi có golden.

### BE-P4-E02 — Tài sản ròng theo thời gian
- Status: done — BE xong 2026-11-06; biểu đồ trên app ở `MOB-P4-E02`
- Module: 3, 14
- Gate: v1
- Depends: BE-P1-007, BE-P4-E01
- DoD: snapshot theo tháng tính từ ledger. Biểu đồ 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm, toàn bộ. Không cộng trùng tiền trong ví và tài sản đầu tư. Test một chuỗi tháng với thu, chi, chuyển khoản và một vị thế.
- Note: BE-P4-E02 xong 2026-11-06: `GET /api/v1/reports/net-worth/history?window=7d|30d|3m|6m|1y|all&on=`, tính lại từ sổ cái mỗi lần đọc (không bảng snapshot, không migration) tại cuối mỗi mốc của `/series`; điểm mới nhất bằng `/net-worth`; ví + cho mượn/đi mượn (gồm khoản đã tất toán sau đó) + vị thế đầu tư phát lại tới từng ngày, không tính trùng. Test: 17 unit domain + 8 integration PostgreSQL (chuỗi 6 tháng thu/chi/chuyển khoản/vàng/cho mượn: 95 → 112 → 117 → 122 triệu). App hiển thị bằng cách lấy dòng của tiền tệ mặc định trong `items` (chốt 2026-11-06: không quy đổi). Kiến trúc: [reports.md](../docs/architecture/reports.md).

### DS-P4-001 — Thiết kế màn đầu tư và tài sản ròng
- Status: done — chốt 2026-11-06
- Module: 3, 12, 14
- Gate: v1
- Depends: BE-P4-E01, BE-P4-E02
- DoD: board P (đầu tư) và Q (tài sản ròng) trên canvas, owner duyệt, pattern doc, bản sao canvas trong repo.
- Note: [P-investments.md](../docs/brand/patterns/P-investments.md), canvas trang `p4` (bản 157). Owner chốt: khoản đầu tư gom danh mục → tài sản → lần mua; bán theo tài sản với giá vốn bình quân; giá bán thành giá hiện tại; "Đã có từ trước" là một lựa chọn trong danh sách ví; thẻ tổng kiểu A2.

### BE-P4-E03 — API đầu tư theo thiết kế đã chốt
- Status: done — 2026-11-06
- Module: 12
- Gate: v1
- Depends: BE-P4-E01, DS-P4-001
- DoD: giữ mô hình vị thế của ADR 014, thêm:
  - % lãi/lỗ dự kiến (basis points, số nguyên) ở từng tài sản, từng lần mua, danh mục và tổng; không tính khoản chưa có giá.
  - Tạo tài sản kèm lần mua đầu trong một lần gọi; trùng danh mục + tên thì thêm lần mua vào tài sản đó.
  - Lần mua "đã có từ trước": không có chân ví, chỉ cộng số lượng và giá vốn; tài sản ròng không tính trùng.
  - Sửa lần mua (số lượng, giá, ngày, ví, ghi chú) và xoá lần mua: sửa/xoá chân ví theo, tính lại giá vốn bình quân và lãi chốt các lần bán sau; chặn nếu số đã bán vượt số còn lại.
  - Bán nhận giá một đơn vị và ví; giá bán lưu thành giá mới (`manual`, ngày bán).
  - Tổng hợp theo danh mục: giá trị, vốn, lãi/lỗ, %, tỷ trọng, danh sách tài sản.
  - Lịch sử giá trị theo thời gian cho tổng đầu tư, danh mục và tài sản (đường mờ ở thẻ tổng), cùng mốc với `/reports/net-worth/history`.
  - Tiền gửi: tạo kèm số tiền gửi và ví (hoặc đã có từ trước) trong một lần gọi.
  - OpenAPI, unit + integration test, cập nhật ADR 014 nếu đổi quy tắc ghi sổ.
- Note: BE-P4-E03 xong 2026-11-06: ADR 014 phần bổ sung (phát lại toàn bộ trade sau mỗi lần ghi, lần mua có sẵn không chân ví, giá của trade thành giá hiện tại, sửa/xoá lần mua kéo theo chân ví, xoá lần cuối xoá tài sản), migration additive `investment_trade_edit`, `POST /investments` có `initialTrade` và gộp trùng tên, trade nhận `priceMinor`/`accountId: null`/`note`, `PATCH/DELETE /investments/{id}/trades/{tradeId}`, `GET /investments?kind=`, `unrealizedBps`/`averageCostMinor`, `summary.byKind` có `shareBps`, `GET /reports/investments/history`. Test: 12 unit + 10 integration PostgreSQL mới; toàn bộ 26 suite integration xanh. Sửa/xoá lần bán chưa làm (thiết kế không có). Kiến trúc: [investments.md](../docs/architecture/investments.md).

### MOB-P4-E02 — Biểu đồ tài sản ròng trên app
- Status: done — 2026-11-06
- Module: 3, 14
- Gate: v1
- Depends: BE-P4-E02, DS-P4-001
- DoD: board Q.1: số hôm nay, thay đổi từ đầu khoảng, biểu đồ, chip 7 ngày → Tất cả, Tài sản · Nợ, Ví · Đầu tư; chạm điểm hiện ngày và số; chưa đủ hai điểm thì ẩn biểu đồ. Lấy dòng tiền tệ mặc định trong `items`. Ô "Tài sản ròng" ở lưới Cá nhân.

### QA-P4-E01 — Test giá vốn, lãi lỗ, tỷ giá
- Status: done — 2026-11-09 (bảng số giá vốn/lãi lỗ/tiền gửi xong 2026-11-06; FX không hỗ trợ ở v1, chủ dự án chốt 2026-11-09)
- Module: 12
- Gate: v1
- Depends: BE-P4-E01
- DoD: bảng số giá vốn và lãi/lỗ đã chốt (FX: v1 không hỗ trợ vị thế khác tiền tệ ví, xem Note), chạy trong test API, gồm vàng theo chỉ/lượng, crypto số lượng lẻ, lãi tiền gửi tới ngày đáo hạn, và một vòng mua → góp thêm → bán một phần. Không dùng số thực dấu phẩy động cho tiền hoặc số lượng.
- Note: 2026-11-06 `investment.spec.ts` (29 test domain) và `investments.integration-spec.ts` (11 test PostgreSQL) phủ vàng chỉ/lượng, crypto 0,12345678, lãi tiền gửi tới đáo hạn (100tr · 12% · 365 ngày = 12tr), mua → góp → bán một phần, làm tròn half-up. Còn thiếu: vị thế khác tiền tệ ví với FX đã chốt; chốt khi quyết định có hỗ trợ hay không.
- Note: 2026-11-09 chốt (chủ dự án): v1 không hỗ trợ vị thế khác tiền tệ ví, nên không có tỷ giá trong đầu tư. Khoản đầu tư luôn cùng tiền tệ với ví mua/bán (API trả 400 nếu khác); khoản "đã có từ trước" dùng tiền tệ hồ sơ. Tài sản ròng và báo cáo vẫn theo từng tiền tệ, không quy đổi. Muốn hỗ trợ sau thì cần ADR mới (nguồn tỷ giá, tiền tệ ghi sổ, làm tròn) và task riêng.
