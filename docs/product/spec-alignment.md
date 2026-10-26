# Đối chiếu spec sản phẩm 0.1

Đối chiếu lần đầu 2026-10-08; cập nhật đóng Phase 1 2026-10-21. Spec: [Freeva Product & Application Specification v0.1](freeva-product-spec.md). Trang này là quyết định trong repo. Spec giữ nguyên bản draft.

## Kết luận

Sổ cái, tiền integer, transfer hai leg, backend là nguồn số dư, và thứ tự “đúng trước khi nhiều tính năng” **khớp** spec (§12, §13, §43, §55, §56).

**Phase 1 (sổ cái) đã đóng 2026-10-21; vẫn không phải product v1 của spec.** Spec §51 và §57 yêu cầu người dùng mới còn lập được ngân sách, mục tiêu, xem báo cáo và nhận insight. Repo giữ Phase 1 là vòng ghi chép; phần còn lại mang `Gate: v1` ở Phase 2 / 3 / 5.

Giữ nguyên số phase và ID đã có. Không dồn ngân sách, mục tiêu, AI vào Phase 1 đã đóng. Gắn `Gate: v1` cho phần spec bắt buộc trước khi gọi là bản phát hành đầu.

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

## Đã vá trong Phase 1 (đóng 2026-10-21)

| Spec | Kết quả | Task |
|---|---|---|
| §8 merchant; §30 tag | API + UI trên thu/chi | `BE-P1-012`, `MOB-P1-011` |
| §6 Home: tài sản, nợ, ròng, dòng tiền | Có trên Home + báo cáo; giao dịch gần theo luồng list | `BE-P1-007`, `MOB-P1-006` |
| §9 ghi chi thường dưới 10 giây | UX siết; bấm giờ thiết bị thật gom smoke residual | `QA-P1-001` |
| §29 lọc merchant, tag, không dấu | `GET …/transactions?search` | `BE-P1-008` |
| §33 offline MVP | Queue + `POST /api/v1/sync` | `BE-P1-009`, `MOB-P1-008` |
| §10 bộ danh mục thiếu + `kind` | API đủ tên + `kind`; cây UI một danh sách | `BE-P1-011`, `MOB-P1-005` |
| §34 export | JSON đủ cho gate sổ cái; CSV không làm ở P1 | `BE-P1-010` |

## Lệch cần vá (sau Phase 1)

| Spec | Hiện trạng | Task |
|---|---|---|
| §10 UI lọc danh mục theo `kind` | Tab Chi · Thu và form ghi đã lọc trên client; API chưa từ chối kind lệch | `BE-P2-010` / `MOB-P2-010` |
| §6.3–6.6 ngân sách, mục tiêu, insight trên Home | Chưa có | `MOB-P2-E02`, `MOB-P3-E01`, `MOB-P5-E04` |
| §34 CSV | Chỉ JSON | Sau P1 nếu beta cần |
| §15 ngân sách và ngưỡng 70/80/90/100 | Epic có DoD | `BE-P2-E02` |
| §16 công thức tiết kiệm/tháng | Epic có DoD | `BE-P3-E01` |
| §18 thẻ: hạn mức còn, dư nợ, ngày sao kê, trả tối thiểu | Ví thẻ chỉ có hạn mức và ngày 1–28 | `BE-P2-E07` |
| §19 lịch sử tài sản ròng | Chỉ ròng hiện tại | `BE-P4-E02` |
| §21 soát tháng | Epic có DoD | `BE-P2-E08` |
| §22–27 tách gợi ý danh mục, insight, OCR, chat, forecast, what-if | Epic AI | `BE-P5-E03` … `E07` |
| §28 AI không bịa số, không tự ghi | Chỉ có câu ở điều kiện phase | DoD từng epic AI |
| §39 cờ server | Client stub luôn tắt | `BE-P5-E08` |
| §37 Free / Premium | Epic subscription không liệt kê quyền | `BE-P7-E01` |
| Tổng quan không quy đổi (pattern B, ADR 006) | Mỗi loại tiền một khối | `BE-P2-013` / `MOB-P2-013` — chỉ hiển thị; sổ cái giữ tiền gốc |

## Gate product v1

Đủ khi các task sau đạt DoD của chính task đó:

1. Phase 1 `Gate: v1` trong backlog — **đã đóng** 2026-10-21 (gồm `BE-P1-011`).
2. Should P1 — **đã đóng** (`QA-P1-001`, `BE-P1-012` / `MOB-P1-011`, …); residual smoke không chặn v1.
3. `Gate: v1` ở phase sau: `BE-P2-E02` / `MOB-P2-E02`, `BE-P3-E01` / `MOB-P3-E01`, `BE-P5-E03` / `MOB-P5-E03`, `BE-P5-E04` / `MOB-P5-E04`, `PRD-P5-E01`.

Hành trình chấp nhận: đăng ký → ví và số dư → danh mục → ghi thu/chi/chuyển → Home đúng số → ngân sách → mục tiêu → báo cáo → một insight có số lấy từ báo cáo, user xác nhận trước mọi ghi đè.
