# Tiến độ thiết kế UI v2 — bàn giao giữa các phiên

Đọc file này trước khi tiếp tục thiết kế. Cập nhật mỗi khi chốt một nhóm.

- Spec: [design-system.md](design-system.md) · token: [`packages/design-tokens`](../../packages/design-tokens/)
- Canvas (riêng tư, của product owner): <https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>
- Bản sao nguồn canvas trong repo: [canvas/](canvas/) (`canvas.json` + mỗi artboard một `.dc.html`). Nếu canvas và repo lệch nhau: tài liệu và token trong repo thắng.
- Nhánh: `feat/DS-P2-001-design-system-v2`

## Trạng thái

| Phần | Trạng thái | Tài liệu |
|---|---|---|
| Foundations, tokens, components, states, guidelines | Chốt | [design-system.md](design-system.md) |
| **A** Onboarding + tài khoản | **Chốt** 2026-10-21 | [patterns/A-onboarding-auth.md](patterns/A-onboarding-auth.md) |
| **B** Tổng quan | **Chốt** 2026-10-21 | [patterns/B-overview.md](patterns/B-overview.md) |
| **C** Giao dịch | **Chốt** 2026-10-21 | [patterns/C-transactions.md](patterns/C-transactions.md) |
| **D** Ví | **Chốt** 2026-10-21 | [patterns/D-wallets.md](patterns/D-wallets.md) |
| **E** Danh mục | **Chốt** 2026-10-21 | [patterns/E-categories.md](patterns/E-categories.md) |
| **F** Báo cáo | **Chốt** 2026-10-21 | [patterns/F-reports.md](patterns/F-reports.md) |
| **G** Cá nhân và cài đặt | **Chốt** 2026-10-21 | [patterns/G-profile-settings.md](patterns/G-profile-settings.md) |
| **H** Đồng bộ | **Chốt** 2026-10-22 | [patterns/H-sync.md](patterns/H-sync.md) |

## Tiến độ code (Flutter)

Thứ tự đã chốt: nền tảng → B → C → D → E → F → G → A → H. Mỗi nhóm một nhánh + một PR vào `develop`; API nhỏ mà màn cần làm luôn trong PR đó, module lớn (ngân sách, thông báo, chế độ khách, deep link email) để trạng thái trống/ẩn.

| Nhóm | Trạng thái | Ghi chú |
|---|---|---|
| Nền tảng (`DS-P2-002`) | Xong | Token → Dart, theme, Inter, Lucide, component trong `lib/core/widgets/`, khung 4 tab + nút +, gallery `/debug/gallery`, golden light/dark |
| B Tổng quan | Chưa | |
| C Giao dịch | Chưa | |
| D Ví | Chưa | |
| E Danh mục | Chưa | |
| F Báo cáo | Chưa | |
| G Cá nhân/Cài đặt | Chưa | |
| A Onboarding/tài khoản | Chưa | |
| H Đồng bộ | Chưa | |

## Việc thiết kế còn lại

Tám nhóm A–H đã chốt. Còn:

- **Popup xoá tài khoản** (nhóm G): chờ quyết định sản phẩm về thời gian chờ huỷ.

## Cách làm đã thống nhất với product owner

1. Mỗi nhóm một (hoặc hai) hàng artboard 390×844 trên trang **05 · Patterns** của canvas, nối link để bấm Play đi được hết luồng.
2. Làm xong một nhóm thì dừng cho product owner duyệt; chốt xong mới ghi vào `docs/brand/patterns/{nhóm}.md`, cập nhật file này và bản sao `canvas/`, rồi commit.
3. Chưa viết code Flutter cho tới khi product owner yêu cầu (`DS-P2-002`, `DS-P2-003`, `DS-P2-004`).

## Phản hồi đã nhận (áp cho mọi nhóm)

- **Chữ ngắn, cô đọng.** Tiêu đề ngắn, tối đa một dòng phụ. Giọng ấm nhưng không màu mè.
- **Không đưa chi tiết kỹ thuật lên UI** (độ dài mã, điều kiện hệ thống, nhãn bước kỹ thuật).
- **Không lạm dụng logo**; logo chỉ ở splash và app icon.
- **Không bắt người dùng nhập tiền sớm.** Hỏi điều dễ trước, việc tốn công sau và cho bỏ qua.
- **Mỗi màn không giống Tổng quan:** dùng đúng loại màn trong spec (danh sách, nhập liệu, chi tiết, cài đặt).
- Ưa: nền sáng, thẻ trắng bo lớn, bottom nav viên thuốc trắng có nút + ở giữa, thẻ số dư lớp màu mờ (chỉ một chỗ), minh hoạ nét vẽ tay, thẻ chọn nền xanh nhạt có dấu tích.
- Không ưa: rập khuôn, nhiều gradient, nhiều chữ giải thích, thiếu điểm nhấn.
- **Bottom nav chỉ ở màn gốc của tab**; vào màn tiếp theo thì ẩn.
- **Chọn ngày trong tháng dùng popup**, không dùng sheet. Thẻ chọn trong form: icon và chữ một dòng.
- **Chữ gợi ý ngắn, rõ, không khô** (ví dụ "Nhập số gần đúng, có thể sửa lại sau.").
- **Trạng thái phải nhìn ra được** (ví dụ mở/thu danh mục con có nút riêng). Không gắn nhãn mà người dùng phải đoán nghĩa ("Của bạn").
- **Bảng chọn màu:** nhiều lựa chọn nhưng không na ná nhau; kiểm bằng ΔE2000.
- **Báo cáo phải đủ ý người dùng cần** (trung bình/ngày, ngân sách, xu hướng) dù API chưa có; vẽ ra và ghi phụ thuộc.
- **Hồ sơ chỉ là thông tin về bạn**; tuỳ chọn của app nằm ở Cá nhân → Ứng dụng. Thiếu API thì vẽ và ghi phụ thuộc.
- **Luồng phụ (góp ý…) không được sơ sài:** có loại, chủ đề, đính kèm, màn cảm ơn.
- **Không bỏ phần UI đã duyệt chỉ vì tính năng chưa có code** (ví dụ chuông thông báo ở Tổng quan).
- **Ẩn số dư chỉ ẩn số dư**, không ẩn thu/chi hay số tiền giao dịch.
- **Đồng bộ chạy ngầm, không làm mất dữ liệu:** chỉ hiện khi có việc cần người dùng; luôn nói rõ thay đổi vẫn nằm trên máy.
- **Màu giữ như spec.** Đã thử ba mức tăng màu (icon danh mục hai tông → nền nhuộm xanh → khối màu đậm đầu màn); product owner chọn giữ nguyên. Không đề xuất lại nếu chưa được hỏi.
- Product owner gửi ảnh tham chiếu thường xuyên: chỉ dùng để thiết kế, **không lưu vào repo**. Điều rút ra từ ảnh thì ghi thành chữ vào spec hoặc file pattern.

## Ghi chú kỹ thuật cho người sửa canvas

- Canvas là Artifact loại Design: file `project/canvas.json` (index, `pages`, `boards`, `order`, `notes`) và `project/*.dc.html`. Ảnh logo đã tải lên dạng asset `/_blob/…` (xem `canvas/Logo.dc.html`).
- Trang canvas: `f` Foundations · `t` Tokens · `c` Components · `s` States · `p` Patterns · `g` Guidelines.
- Màu trong artboard là hex theo token v2 (ink `#22283A`, canvas `#FCFDFF`, action `#3F67D1`, wash ở `.wash`).
