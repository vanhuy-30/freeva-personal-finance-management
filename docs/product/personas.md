# Personas

Task `PRD-P0-001`. Giả định làm việc đến khi có phỏng vấn — không phải kết quả nghiên cứu. Thị trường đầu: Việt Nam. Use case ghi chi: [use-cases.md](use-cases.md). Vision: [vision.md](vision.md).

Tuổi và nghề dưới đây là kim chỉ nam **recruit beta** và **copy store**, không phải cổng sản phẩm. Không chặn đăng ký hay ẩn tính năng theo tuổi/nghề. Ai tự quản lý tiền cá nhân bằng ngân hàng hoặc ví điện tử đều dùng được vòng lặp ghi chi.

## Thị trường đầu (Việt Nam)

Chỉ những gì repo đã chốt hoặc giả định vận hành. Không thống kê thị phần, đối tác ngân hàng, hay IAP.

| Khía cạnh | Quyết định |
|---|---|
| Locale | `vi` mặc định; `en` thứ hai |
| Tiền | `VND`, minor unit = 1 đồng ([ADR 006](../architecture/adr/006-money-and-fx.md)) |
| Múi giờ | `Asia/Ho_Chi_Minh` |
| Tìm kiếm | tiếng Việt không dấu (Should Phase 1) |
| Loại ví | `cash` \| `bank` \| `ewallet` \| `credit` ([data-model](../architecture/data-model.md)) |
| Pháp lý | tinh thần PDPD — [privacy-compliance](../architecture/privacy-compliance.md); ToS/privacy nháp `PRD-P0-002`: [điều khoản](../legal/terms-of-service.md), [bảo mật](../legal/privacy-policy.md) |

**Bộ danh mục mặc định (đề xuất, seed = [BE-P1-006](../../tasks/phase-01.md)):** ăn uống, đi lại, nhà ở, hóa đơn, mua sắm, sức khỏe, giáo dục, giải trí, chi tiêu gia đình (workaround phân loại — xem dưới), khác.

**Won't beta:** multi-user / hộ gia đình ([module 16](modules/16-family.md), Phase 6), kết nối ngân hàng API, AI, web consumer.

## P1 — Knowledge worker ghi chép hằng ngày (beta 100%)

Nhân viên văn phòng / knowledge worker Việt Nam, khoảng **23–32** tuổi, thu nhập ổn định (lương), tự quản lý tiền cá nhân. Dùng ngân hàng và ví điện tử. Hiện theo dõi chi tiêu bằng trí nhớ, ghi chú, hoặc spreadsheet bỏ dở.

Đây là persona **duy nhất** cho recruit và thiết kế beta Phase 1. Không cố phục vụ cùng lúc sinh viên, freelancer thu nhập thất thường, hộ gia đình, và nhà đầu tư.

### Việc cần làm (JTBD)

Biết tiền đi đâu trong tháng, ghi chi ngay sau khi trả, nhìn còn bao nhiêu trên từng ví — không cần ngân sách hay mục tiêu lúc này.

### Đau

- Cuối tháng không giải thích được số dư.
- Excel / note bỏ dở vì ghi chậm, dễ quên.
- Tiền nằm rải ngân hàng + ví điện tử (+ thẻ nếu có); không có một chỗ đúng.

### Việc trên Freeva (Phase 1)

- Tạo vài ví (`bank`, `ewallet`; `cash` / `credit` nếu dùng).
- Ghi chi nhanh — [UC-EXP-01](use-cases.md#uc-exp-01).
- Ghi chi thẻ nếu có — [UC-EXP-02](use-cases.md#uc-exp-02).
- Ghi muộn / sửa / xóa — [UC-EXP-03](use-cases.md#uc-exp-03).
- Xem số dư derived và báo cáo kỳ cơ bản.

### Thành công

Onboarding → ví → giao dịch đầu không cần hỗ trợ. Số dư sau thu/chi/chuyển/sửa/xóa đúng. Người dùng ghi được chi hằng ngày mà không chuyển lại spreadsheet.

### Không thiết kế MVP quanh

Sinh viên (thu nhập không ổn định, không phải đối tượng recruit). Freelancer thu nhập thất thường (store listing có thể nhắc freelancer **thu nhập tương đối đều** — không phải persona beta). Hộ gia đình nhiều người. Nhà đầu tư / robo-advisor.

## P2 — Người kiểm soát ngân sách (Phase 2)

Đã ghi chép được vài tuần (thường tiến hóa từ P1). Cần hạn mức danh mục, hóa đơn, nhắc hạn.

Không recruit vào beta Phase 1. Không mở Module 6–8 sớm để “cho P2”.

## P3 — Người lập kế hoạch (Phase 3+)

Có mục tiêu (du lịch, quỹ khẩn cấp), khoản vay, sổ tiết kiệm; sau đó tài sản (Phase 4). Cần số liệu minh bạch, không “AI hứa hẹn”.

Nhà đầu tư không phải đối tượng thiết kế MVP. Module 9–12 theo roadmap.

## P4 — Nhân viên vận hành (web admin)

Staff nội bộ, khác user app ([glossary](glossary.md)). Tra cứu tài khoản theo phân quyền (Phase 0 tối thiểu). Dashboard kinh doanh = Phase 7. Không phải persona store listing.

## Quyết định làm việc (PRD-P0-001)

| Câu hỏi | Quyết định |
|---|---|
| Persona beta 100%? | P1. Sinh viên / freelancer thất thường / gia đình / nhà đầu tư = nhóm lân cận hoặc phase sau. |
| Hộ gia đình trước Phase 6? | Không. Không multi-user, shared wallet, ACL, chia ngân sách, đối soát hai người. Workaround Phase 1: category hoặc tag “Chi tiêu gia đình”, hoặc ví phân loại “dùng chung” trên **một** user — không phải [module 16](modules/16-family.md). |
| Store listing? | Rộng hơn beta: **“Người đi làm 22–35 tuổi”**. Ưu tiên nhân viên văn phòng, công nghệ, marketing, tài chính, sales, freelancer thu nhập tương đối đều. Không copy hẹp kiểu “nhân viên văn phòng 25–30 tuổi”. |

## Còn mở sau interview

Không chặn Phase 1:

- Danh mục mặc định nào P1 dùng nhiều nhất (chỉnh seed `BE-P1-006`).
- Số ví điển hình (2–4 là giả định hiện tại).
