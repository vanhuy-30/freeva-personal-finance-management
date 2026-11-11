# Đối chiếu spec sản phẩm 0.1

Đối chiếu lần đầu 2026-10-08; cập nhật đóng Phase 1 2026-10-21. Spec: [Freeva Product & Application Specification v0.1](freeva-product-spec.md). Trang này là quyết định trong repo. Spec giữ nguyên bản draft.

## Kết luận

Sổ cái, tiền integer, transfer hai leg, backend là nguồn số dư, và thứ tự “đúng trước khi nhiều tính năng” **khớp** spec (§12, §13, §43, §55, §56).

**Phase 1 (sổ cái) đã đóng 2026-10-21; vẫn không phải product v1 của spec.** Spec §51 và §57 yêu cầu người dùng mới còn lập được ngân sách, mục tiêu, xem báo cáo và nhận insight. Repo giữ Phase 1 là vòng ghi chép; phần còn lại mang `Gate: v1` ở Phase 2 / 3 / 4.

**Quyết định chủ dự án 2026-11-02:** theo dõi tài sản và đầu tư (module 12) vào product v1; gợi ý danh mục, insight cơ bản và phần AI đi kèm (cờ server, consent AI) ra sau v1. Spec §51 xếp AI cơ bản vào MVP và §52 xếp investment tracking sau MVP; repo đảo hai mục này.

Giữ nguyên số phase và ID đã có. Không dồn ngân sách, mục tiêu, đầu tư vào Phase 1 đã đóng. Gắn `Gate: v1` cho phần spec bắt buộc trước khi gọi là bản phát hành đầu.

## Khớp

- Vòng Track → Understand → Control → Improve. Non-goal: giao dịch ngân hàng trực tiếp, trading, thanh toán, marketplace.
- Auth email, Google, Apple, khóa PIN/sinh trắc. Ví tiền mặt, ngân hàng, ví điện tử, thẻ. Thu, chi, chuyển khoản cân bằng.
- Danh mục mặc định tiếng Việt, tùy chỉnh, ẩn, cây cha-con.
- Tiền `BigInt` minor units. Báo cáo và số dư tính ở backend.
- Admin không được mặc định xem dữ liệu tài chính. Paywall không chặn ghi chép, xuất và xóa tài khoản.
- Flutter feature-based, presentation / domain / data.

## Lệch có chủ đích

| Spec | Repo | Lý do |
|---|---|---|
| §51 gọi budget, goal, insight cơ bản là MVP | Ngân sách ở Phase 2, mục tiêu ở Phase 3 (`Gate: v1`). Gợi ý danh mục và insight theo quy tắc ở Phase 5; phần cần AI ở Phase 8 | Sổ cái phải đúng trước (§55). AI ra sau v1 (2026-11-02); chưa chốt hướng AI nên gom về Phase 8 (2026-11-11). |
| §52 xếp investment tracking sau MVP | Module 12 ở Phase 4, `Gate: v1` | Quyết định 2026-11-02: v1 trả lời đủ "tiền nằm ở đâu" gồm cả tài sản và đầu tư. |
| §11 có Saving, Investment ngay trong loại tài khoản | Phase 1 có bốn loại: cash, bank, ewallet, credit | Đầu tư là Phase 4 (`Gate: v1`), vị thế tách khỏi ví tiền. Mục tiêu v1 gắn ví đã có, không cần loại mới. |
| §48 tab Insights | Phase 1: Home, Giao dịch, `+`, Thêm | Tab Insights mở khi có insight (`BE-P5-E04`, sau v1). |
| Không có module hóa đơn / lịch riêng | Module 8, 15 ở Phase 2 | Bổ sung trên định kỳ và nhắc. Không thay ngân sách. |
| Mục tiêu là chỗ theo dõi tiết kiệm | Tiền gửi có kỳ hạn là một loại tài sản trong module 12 | Module 11 gộp vào 12 (2026-11-02). |
| Không có module hóa đơn / lịch riêng | Hóa đơn gộp vào định kỳ, lịch chỉ là màn xem (`BE-P3-001`) | Bớt ba khái niệm chồng nhau (2026-11-02). |
| §53 import sao kê file | Không làm (2026-11-11). Có nhập CSV từ app khác (`BE-P3-011`); API ngân hàng ở Phase 6 | Chủ dự án thấy không cần. API trực tiếp vẫn là non-goal của v1. |
| §22–27 gọi là tính năng AI | Gợi ý danh mục, insight, dự báo chi, what-if tính bằng quy tắc ở Phase 5. OCR, Ask Freeva ở Phase 8 | Chưa chốt AI chạy trên máy hay dịch vụ ngoài (2026-11-11). |
| §39 chỉ nêu cờ bật/tắt | Cờ và cấu hình (ngưỡng, giới hạn, danh sách) đều ở server, sửa trên web admin; app không hardcode | Quyết định 2026-11-11 (`BE-P5-E08`, `WA-P5-001`, `BE-P5-001`). |

## Đã vá trong Phase 1 (đóng 2026-10-21)

| Spec | Kết quả | Task |
|---|---|---|
| §8 merchant; §30 tag | API + UI trên thu/chi | `BE-P1-012`, `MOB-P1-011` |
| §6 Home: tài sản, nợ, ròng, dòng tiền | Có trên Home + báo cáo; giao dịch gần theo luồng list | `BE-P1-007`, `MOB-P1-006` |
| §9 ghi chi thường dưới 10 giây | UX siết; bấm giờ thiết bị thật gom smoke residual | `QA-P1-001` |
| §29 lọc merchant, tag, không dấu | `GET …/transactions?search` | `BE-P1-008` |
| §33 offline MVP | Queue + `POST /api/v1/sync` | `BE-P1-009`, `MOB-P1-008` |
| §10 bộ danh mục thiếu + `kind` | API đủ tên + `kind`; tab Chi · Thu; API từ chối kind lệch khi ghi/sửa (`CATEGORY_KIND_MISMATCH`) | `BE-P1-011`, `MOB-P1-005`, `BE-P2-010` |
| §34 export | JSON đủ cho gate sổ cái; CSV không làm ở P1 | `BE-P1-010` |

## Lệch cần vá (sau Phase 1)

| Spec | Hiện trạng | Task |
|---|---|---|
| §6.3–6.6 ngân sách, mục tiêu, insight trên Home | Ngân sách có thanh trên Home; mục tiêu / insight chưa | `MOB-P2-E02` (ngân sách), `MOB-P3-E01`; insight `MOB-P5-E04` sau v1 |
| §34 CSV | Chỉ JSON | Sau P1 nếu beta cần |
| §15 ngân sách và ngưỡng 70/80/90/100 | API + mobile theo DoD | `BE-P2-E02` / `MOB-P2-E02` |
| §16 công thức tiết kiệm/tháng | API có công thức + test (2026-11-02); mobile `MOB-P3-E01` còn | `BE-P3-E01` |
| §18 thẻ: hạn mức còn, dư nợ, ngày sao kê, trả tối thiểu | API + mobile: hạn mức, ngày 1–28, số trả tối thiểu; dư nợ / hạn mức còn suy từ số dư; cảnh báo hộp thư | `BE-P2-E07` / `MOB-P2-E07` |
| §19 lịch sử tài sản ròng | Chỉ ròng hiện tại | `BE-P4-E02` |
| §21 soát tháng | Epic có DoD | `BE-P2-E08` |
| §22–27 tách gợi ý danh mục, insight, OCR, chat, forecast, what-if | Phase 5 theo quy tắc; OCR, chat ở Phase 8 | `BE-P5-E03`, `E04`, `E06`, `E07`; `BE-P8-E01`, `BE-P8-E03` |
| §28 AI không bịa số, không tự ghi | Chỉ có câu ở điều kiện phase | DoD từng epic AI |
| §39 cờ server | Client stub luôn tắt | `BE-P5-E08`, `WA-P5-001`, `MOB-P5-E08` |
| §37 Free / Premium | Epic subscription không liệt kê quyền | `BE-P7-E01` |
| Tổng quan không quy đổi (pattern B, ADR 006) | Mỗi loại tiền một khối | `BE-P2-013` / `MOB-P2-013` — chỉ hiển thị; sổ cái giữ tiền gốc |

## Gate product v1

Đủ khi các task sau đạt DoD của chính task đó:

1. Phase 1 `Gate: v1` trong backlog — **đã đóng** 2026-10-21 (gồm `BE-P1-011`).
2. Should P1 — **đã đóng** (`QA-P1-001`, `BE-P1-012` / `MOB-P1-011`, …); residual smoke không chặn v1.
3. `Gate: v1` ở phase sau: `BE-P2-E02` / `MOB-P2-E02` (**đã đóng** 2026-10-30), `BE-P3-E01` / `MOB-P3-E01`, `BE-P3-001` … `BE-P3-012` (gộp chồng chéo + bổ sung, 2026-11-02), `BE-P4-E01` / `MOB-P4-E01`, `BE-P4-E02`, `QA-P4-E01`.

Phase 5 không còn `Gate: v1` từ 2026-11-02.

Hành trình chấp nhận: đăng ký → ví và số dư → danh mục → ghi thu/chi/chuyển → Home đúng số → ngân sách → mục tiêu → tài sản và đầu tư (tách khỏi ví, giá có nguồn và thời điểm) → tài sản ròng theo thời gian → báo cáo và thẻ soát tháng. Insight không còn trong hành trình v1.
