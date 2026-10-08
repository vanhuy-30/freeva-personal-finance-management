# Đối chiếu spec sản phẩm 0.1

Đối chiếu ngày 2026-10-08 với [Freeva Product & Application Specification v0.1](freeva-product-spec.md). Trang này là quyết định trong repo. Spec giữ nguyên bản draft.

## Kết luận

Sổ cái, tiền integer, transfer hai leg, backend là nguồn số dư, và thứ tự “đúng trước khi nhiều tính năng” **khớp** spec (§12, §13, §43, §55, §56).

**Phase 1 trong repo không phải product v1 của spec.** Spec §51 và §57 yêu cầu người dùng mới còn lập được ngân sách, mục tiêu, xem báo cáo và nhận insight. Repo đang gọi Phase 1 là MVP trong khi mới phủ vòng ghi chép.

Giữ nguyên số phase và ID đã có. Không dồn ngân sách, mục tiêu, AI vào Phase 1 đang làm. Gắn `Gate: v1` cho phần spec bắt buộc trước khi gọi là bản phát hành đầu.

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
| §51 gọi budget, goal, insight cơ bản là MVP | Ngân sách ở Phase 2, mục tiêu ở Phase 3, AI ở Phase 5 | Sổ cái phải đúng trước (§55). Các epic đó mang `Gate: v1`. |
| §11 có Saving, Investment ngay trong loại tài khoản | Phase 1 có bốn loại: cash, bank, ewallet, credit | Đầu tư là Phase 4. Mục tiêu v1 gắn ví đã có, không cần loại mới. |
| §48 tab Insights | Phase 1: Home, Giao dịch, `+`, Thêm | Tab Insights mở khi có insight (`BE-P5-E04`). |
| Không có module hóa đơn / lịch riêng | Module 8, 15 ở Phase 2 | Bổ sung trên định kỳ và nhắc. Không thay ngân sách. |
| Mục tiêu là chỗ theo dõi tiết kiệm | Module 11 tiền gửi có kỳ hạn riêng | Không nằm spec v1. Làm sau, được đóng nếu beta không cần. |
| §53 import sao kê file | Import file ở Phase 5; API ngân hàng ở Phase 6 | API trực tiếp vẫn là non-goal của v1. |

## Lệch cần vá

| Spec | Hiện trạng | Task |
|---|---|---|
| §10 danh mục thu/chi tách và thiếu Cà phê, điện nước, internet, điện thoại, subscription, bảo hiểm, thuế, freelance, kinh doanh, đầu tư, hoàn tiền | Một cây dùng chung; seed 15 mục; bootstrap không bổ sung | `BE-P1-011`, UI `MOB-P1-005` |
| §8 merchant; §30 tag | Giao dịch nhận `tagIds` nhưng không có API tạo tag; không có merchant | `BE-P1-012`, `MOB-P1-011` |
| §6 Home: tài sản, nợ, ròng, dòng tiền, giao dịch gần | `MOB-P1-006` chưa có DoD | `BE-P1-007`, `MOB-P1-006` |
| §6.3–6.6 ngân sách, mục tiêu, insight trên Home | Chưa có task gắn vào Home | `MOB-P2-E02`, `MOB-P3-E01`, `MOB-P5-E04` |
| §9 ghi chi thường dưới 10 giây | `MOB-P1-004` xong về số bước, chưa đo thời gian | `QA-P1-001` |
| §29 lọc merchant, tag, không dấu | Search chưa làm | `BE-P1-008` |
| §33 offline: UUID, trạng thái sync, timestamp, retry | Epic sync không có DoD | `BE-P1-009`, `MOB-P1-008` |
| §34 CSV và JSON | Task export chỉ nói JSON | `BE-P1-010` |
| §15 ngân sách và ngưỡng 70/80/90/100 | Epic không có tiêu chí nhận | `BE-P2-E02` |
| §16 công thức tiết kiệm/tháng | Epic mục tiêu không có ví dụ số | `BE-P3-E01` |
| §18 thẻ: hạn mức còn, dư nợ, ngày sao kê, trả tối thiểu | Ví thẻ chỉ có hạn mức và ngày 1–28 | `BE-P2-E07` |
| §19 lịch sử tài sản ròng | Chỉ có ròng hiện tại trong báo cáo Phase 1 | `BE-P4-E02` |
| §21 soát tháng | Không có task | `BE-P2-E08` |
| §22–27 tách gợi ý danh mục, insight, OCR, chat, forecast, what-if | Một epic AI | `BE-P5-E03` … `E07` |
| §28 AI không bịa số, không tự ghi | Chỉ có câu ở điều kiện phase | DoD từng epic AI |
| §39 cờ server | Client stub luôn tắt | `BE-P5-E08` |
| §37 Free / Premium | Epic subscription không liệt kê quyền | `BE-P7-E01` |

## Gate product v1

Đủ khi các task sau đạt DoD của chính task đó:

1. Phase 1 còn mở: `MOB-P1-001`, `MOB-P1-005`, `BE-P1-007`, `MOB-P1-006`, `BE-P1-008`, `MOB-P1-007`, `BE-P1-009`, `BE-P1-010`, `BE-P1-011`, `INF-P1-001`, `SEC-P1-001`.
2. Should, không chặn v1 nếu thiếu: `BE-P1-012`, `MOB-P1-011`, `MOB-P1-008`, `MOB-P1-009`, `QA-P1-001`.
3. `Gate: v1` ở phase sau: `BE-P2-E02` / `MOB-P2-E02`, `BE-P3-E01` / `MOB-P3-E01`, `BE-P5-E03` / `MOB-P5-E03`, `BE-P5-E04` / `MOB-P5-E04`, `PRD-P5-E01`.

Hành trình chấp nhận: đăng ký → ví và số dư → danh mục → ghi thu/chi/chuyển → Home đúng số → ngân sách → mục tiêu → báo cáo → một insight có số lấy từ báo cáo, user xác nhận trước mọi ghi đè.
