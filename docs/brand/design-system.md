# Freeva Design System v2

Task `DS-P2-001`. Áp cho `apps/mobile`; `apps/web-admin` chỉ dùng chung token màu.
Nguồn token: [`packages/design-tokens/tokens.json`](../../packages/design-tokens/tokens.json).
Canvas thiết kế (riêng tư, cần được chia sẻ mới mở được):
<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>. Ảnh tham chiếu:
[references/](references/).

Khi tài liệu này và canvas lệch nhau, **token trong repo thắng**, rồi tới tài liệu
này, cuối cùng là canvas.

## 1. Nguyên tắc

Ba tính từ: **uy tín · năng động · tự do**. Không được: generic, rối, giả tạo.

| Tính từ | Quy tắc |
|---|---|
| Uy tín | Ink `#22283A` làm điểm neo. Số tiền dùng chữ số tabular, không trang trí quanh số. Mọi chữ đạt WCAG AA. |
| Năng động | Nút + luôn trong tầm ngón cái. Phản hồi chạm trong 150 ms. Ghi một khoản chi dưới 10 giây (QA-P1-001). |
| Tự do | Nhiều khoảng trắng, một việc chính trên mỗi màn, ít chữ giải thích. |

| Tránh | Cách tránh |
|---|---|
| Generic | Dùng chữ ký riêng: lớp màu mờ ở thẻ số dư, bottom nav viên thuốc, nút + ở giữa. |
| Rối | Mỗi màn tối đa một vùng nền màu đậm; màu dữ liệu theo thứ tự cố định. |
| Giả tạo | Gradient chỉ ở thẻ số dư; bo góc theo thang; bóng đổ nhẹ. |

### Năm loại màn hình

| Loại | Cấu trúc | Ví dụ |
|---|---|---|
| Tổng quan | Lời chào, thẻ số dư có lớp màu, menu nhanh, khối tóm tắt | Tổng quan |
| Danh sách | Tiêu đề lớn, tìm kiếm, chip lọc, nhóm theo ngày. Không có lớp màu | Giao dịch, Ví, Danh mục, Nhãn |
| Nhập liệu | Thanh trên có nút đóng, trường chính lớn, nút lưu cố định ở đáy. Ẩn bottom nav | Ghi chi, Thêm ví, Đăng nhập |
| Chi tiết | Bottom sheet hoặc màn đẩy vào, số tiền ở đầu, hành động ở đáy | Chi tiết giao dịch, chi tiết ví |
| Cài đặt | Thẻ hồ sơ, nhóm menu trong thẻ trắng, dòng có icon và mũi tên | Cá nhân, Cài đặt, Pháp lý, FAQ |

## 2. Foundations

### Màu

Nền trung tính chiếm khoảng 75% diện tích. Màu brand để nhấn:

| Màu | Hex | Tỷ lệ | Dùng cho |
|---|---|---|---|
| Primary | `#5680E9` | 10–15% | Nút +, tab đang chọn, chuỗi dữ liệu chính |
| Accent | `#8860D0` | 3–5% | Điểm nhấn phụ, nhãn, nhóm dữ liệu thứ hai |
| Secondary | `#5AB9EA` | 5–10% | Biểu đồ, trạng thái thông tin |
| Highlight | `#84CEEB` | có chọn lọc | Lớp màu mờ thẻ số dư. **Không làm chữ** |
| Muted | `#C1C8E4` | có chọn lọc | Nhóm "Khác" trong biểu đồ. **Không làm chữ** |

Mỗi màu brand có thang 50–900 trong `primitive.color`. Màu gốc 500 không đạt AA khi
làm chữ trên nền trắng (primary 3.7:1), nên **chữ và nền nút dùng bậc 600–700**:
nút và link `#3F67D1`, chữ số tiền thu `#23795A`, chữ lỗi `#B83434`. Chi tiết ở
[palette.md](palette.md).

**Lớp màu mờ (wash):** nền `#ECEFFA`, highlight 50% ở góc trên phải, accent 22% ở
góc dưới trái. Chỉ dùng cho thẻ số dư, trên màn Tổng quan và chi tiết ví.

### Typography

Inter 400/500/600, đóng gói trong app cho cả iOS và Android.

| Token | Cỡ/dòng | Đậm | Giãn chữ | Dùng |
|---|---|---|---|---|
| `moneyDisplay` | 40/44 | 600 | −1.2 | Số dư chính (màn 320 pt: 32/36) |
| `moneyL` | 28/32 | 600 | −0.6 | Số tiền ở màn nhập, chi tiết |
| `titleXl` | 28/34 | 600 | −0.6 | Tiêu đề lớn màn gốc của tab |
| `headline` | 24/30 | 600 | −0.4 | Lời chào, tiêu đề màn khoá |
| `titleL` | 17/24 | 600 | 0 | Tiêu đề khối, tiêu đề thanh trên |
| `titleM` | 15/22 | 600 | 0 | Tiêu đề thẻ |
| `body` | 15/22 | 400–500 | 0 | Nội dung, tên giao dịch |
| `bodyS` | 13/18 | 400 | 0 | Dòng phụ |
| `label` | 12/16 | 500 | 0 | Nhãn menu nhanh, chú thích |
| `overline` | 11/14 | 600 | +1.6 | Tiêu đề nhóm in hoa |

- Số tiền luôn tabular (`tnum`). Ký hiệu ₫ bằng nửa cỡ số, màu muted, đặt sau số.
- Line-height tối thiểu 1.3× để dấu tiếng Việt không chạm dòng trên.
- Cỡ chữ hệ thống tới 1.3×; riêng `moneyDisplay` giới hạn 1.15×. Số tiền không bị cắt bằng "…".

### Spacing, layout, hình khối

- Lưới 4 pt: `space.1…12` = 4, 8, 12, 16, 20, 24, 32, 48.
- Một cột, lề 20 (16 khi màn ≤ 340 pt). Màn ≥ 430 pt và tablet: nội dung tối đa 480, căn giữa.
- Nội dung cuộn chừa 120 ở đáy cho bottom nav nổi.
- Radius: 12 ô icon · 16 input, ô con · 20 list, tile · 24 thẻ · 28 sheet · full cho nút, chip, nav.
- Viền: 1 mặc định · 1.5 đang chọn · focus = viền 1.5 primary + vòng 4 px.
- Elevation: `0` viền · `1` thẻ, list · `2` nav, sheet, toast.
- Vùng chạm tối thiểu 44 pt (Android 48 dp). Nút 52, nút cuối form 56, dòng list 56.

### Icon và minh hoạ

- Thư viện **`lucide_icons_flutter` 4.0.1**. Chỉ dùng Lucide, không trộn Material Icons.
  Icon Lucide không có thì vẽ trên lưới 24, đầu tròn, độ dày nét khớp gói.
- Ba kiểu: outline (mặc định) · hai tông = nền tint 50 + nét 600/700 (ví, danh mục,
  menu nhanh) · tô đặc chỉ cho trạng thái đang chọn.
- Cỡ: 16 trong chip, 20 trong nút và nav, 24 độc lập. Không emoji.
- Trạng thái trống: **animation tự vẽ bằng Flutter** (`AnimationController` + `CustomPainter`)
  từ ba nét chữ F, trôi lệch nhịp, chu kỳ 3 s. Không Lottie, không ảnh stock hay 3D.
  Màu lấy từ token. Bật giảm chuyển động thì hiện khung tĩnh.

## 3. Design tokens

Ba tầng trong `tokens.json`:

1. **`primitive`** — giá trị thô (thang màu). Không dùng trực tiếp trong widget.
2. **`semantic`** — vai trò, mỗi lá có `light` và `dark`. Dark mode chỉ đổi tầng này.
3. **`component`** — nơi dùng, tham chiếu semantic. Widget đọc tầng này hoặc semantic.

Tham chiếu viết `{primitive.color.blue.600}`. Tên theo
`{nhóm}.{vai trò}.{biến thể}`, ví dụ `semantic.color.action.primaryPressed`.

Ngoài màu: `typography`, `space`, `radius`, `size`, `layout`, `border`, `elevation`,
`motion`.

**Nhánh `color` (legacy) giữ nguyên key.** Đây là bảng màu danh mục mà API
`GET /categories/options` trả về và backend kiểm tra
([category-tokens.generated.ts](../../backend/api/src/modules/categories/category-tokens.generated.ts)).
Được đổi giá trị cho khớp v2, không đổi hay xoá key nếu chưa có migration cho
`colorToken` đã lưu.

Lệnh (trong `packages/design-tokens`):

| Lệnh | Việc |
|---|---|
| `node scripts/build.mjs` | Sinh `tokens.css` (biến legacy + semantic + scale). |
| `node scripts/check.mjs` | Kiểm tra tham chiếu, tương phản AA cho các cặp chữ/nền ở cả light và dark, và cấm highlight/muted làm chữ. |
| `pnpm check` | Hai việc trên, báo lỗi nếu `tokens.css` chưa sinh lại. |

Sinh Dart cho Flutter thuộc `DS-P2-002`.

## 4. Components

| Nhóm | Thành phần |
|---|---|
| Buttons | Primary (`action.primary`), Ink (bước tiếp theo), Secondary (viền), Destructive, Text. Cỡ L 56 · M 52 · S 44 · XS 40. Nút icon 44 / 36 trên thẻ. Nút + 52 chỉ ở giữa bottom nav. Một nút primary mỗi màn. |
| Inputs & selection | Trường nhập nhãn trong ô; focus, lỗi, khoá. Ô chọn mở sheet. Ô tìm kiếm. Nhập số tiền bằng bàn phím riêng có phím `000`. Segmented (2–4 lựa chọn), chip chọn (viền ink), chip lọc (nền ink), công tắc, radio, checkbox. |
| Navigation | Bottom nav 4 tab + nút +, chỉ icon, mục đang chọn là vòng ink. Thanh trên: tiêu đề lớn · màn đẩy vào · modal. Segmented trong trang. Bottom sheet. |
| Cards & data | Thẻ số dư (wash, duy nhất), thẻ ví, menu nhanh, ô chỉ số, thanh tiến độ (hạn mức thẻ), thanh phân bổ, biểu đồ cột theo kỳ. |
| Lists | Dòng giao dịch (icon 40 · tên + danh mục · ví · số tiền có dấu, không ₫), nhóm theo ngày kèm tổng ròng, vuốt để sửa/xoá, danh sách cài đặt. |
| Feedback | Toast ink (4 s, 6 s nếu có Hoàn tác), banner trong luồng nội dung, hộp thoại xác nhận, trạng thái trống, skeleton, lỗi có nút thử lại. |

Thu/chi/chuyển: chi màu ink + dấu −; thu màu `money.income` + dấu +; chuyển ví màu
muted, không dấu. Màu đỏ chỉ cho lỗi và cảnh báo, không cho khoản chi.

## 5. Trạng thái

Mọi component tương tác có: **default · pressed · focused · disabled · loading · error**.

- Pressed: tối một bậc hoặc nền subtle, thu 0.97, 100 ms. Rung nhẹ cho nút + và phím số.
- Focused: viền 1.5 primary + vòng 4 px (bàn phím ngoài, Switch Access).
- Disabled: đổi sang token disabled, không chỉ giảm opacity; nói lý do gần đó.
- Loading: giữ kích thước, chặn chạm lặp; danh sách dùng skeleton.
- Error: viền lỗi + chữ hướng dẫn + icon; không báo lỗi chỉ bằng màu.

## 6. Patterns

| Pattern | Quy tắc chính |
|---|---|
| Data display | Một con số lớn mở màn; một thẻ có lớp màu; số rút gọn chỉ ở chip và biểu đồ; bật ẩn số dư thì mọi số tiền trên màn đều ẩn. |
| Search & filter | Chip lọc luôn hiện; ô tìm mở từ kính lúp; tìm tiếng Việt không dấu, cập nhật sau 300 ms; tổng thu/chi theo bộ lọc; không kết quả có nút "Xoá bộ lọc". |
| Form | Số tiền focus sẵn; mặc định ví gần nhất, hôm nay, danh mục hay dùng; trường phụ gấp lại; lưu xong đóng màn + toast Hoàn tác. |
| Settings | Thẻ hồ sơ, email che một phần; nhóm Quản lý · Ứng dụng · Hỗ trợ; bật/tắt có hiệu lực ngay; hành động nguy hiểm ở cuối và luôn hỏi lại. |
| Authentication | Sinh trắc học trước, PIN 6 số dự phòng; chưa mở khoá thì không hiện số tiền nào, kể cả ở màn chuyển app; sai 5 lần thì đăng nhập lại. |

## 7. Guidelines

### Điều hướng và IA

- 4 tab: **Tổng quan · Giao dịch · Báo cáo · Cá nhân**, nút + ở giữa mở Ghi chi/Thu/Chuyển.
- Trước khi vào app: Splash 1,8 s → Giới thiệu (lần đầu) → Đăng nhập → Mở khoá.
- **Push** khi đi sâu vào nội dung (giữ bottom nav ở cấp 1–2). **Modal** khi tạo/sửa dữ
  liệu (ẩn bottom nav). **Sheet** khi chọn nhanh hoặc xem nhanh.
- Tối đa ba cấp. Nhấn lại tab đang chọn: cuộn lên đầu, lần hai về gốc của tab.

### Accessibility, adaptive, nền tảng

- Nhãn đọc màn hình đọc đủ số tiền: "trừ 65 nghìn đồng, Phở Thìn, ăn uống, hôm nay".
  Số đang ẩn đọc là "số dư đã ẩn".
- Không phân biệt chỉ bằng màu: thu/chi có dấu, lỗi có icon và chữ, biểu đồ có chú thích.
- Chỉ hướng dọc. Nút lưu nổi trên bàn phím hệ thống.
- iOS/Android cùng giao diện; khác ở: cử chỉ quay lại, tên sinh trắc học, rung (không ripple),
  thanh trạng thái/edge-to-edge. Chọn ngày giờ dùng sheet của Freeva trên cả hai.

### Chuyển động

| Token | Thời lượng | Dùng |
|---|---|---|
| `press` | 100 ms | Nhấn |
| `fast` | 150 ms | Đổi trạng thái, đổi tab (mờ chéo) |
| `base` | 250 ms | Sheet, modal, chuyển màn |
| `slow` | 400 ms | Số dư đếm lên, một lần mỗi phiên |

Easing `cubic-bezier(0.2, 0, 0, 1)`. Sheet trồi từ đáy, chi tiết trượt từ phải.
Giảm chuyển động: bỏ trượt, thu phóng, đếm số; chỉ mờ dần 150 ms; splash tĩnh.

### Nội dung và UX writing

- Giọng văn: rõ ràng, thân thiện nhưng không suồng sã, **không phán xét chi tiêu**, ít chữ giải thích.
- Nút là động từ cụ thể ("Lưu khoản chi"), không "OK".
- Lỗi = chuyện gì xảy ra + dữ liệu có an toàn không + làm gì tiếp. Không đổ lỗi cho người dùng.
- Định dạng: `18.500.000 ₫`; rút gọn `18,5tr`, `850k`; "Hôm nay", "Thứ Hai, 20/10";
  giờ 24h; `−6% so với T9`.
- Thuật ngữ: **Ví** (không "tài khoản"), **Ghi chi/Ghi thu** (hành động), **Khoản chi** (bản ghi),
  **Chuyển ví** (giữa hai ví của mình, không "chuyển khoản"), **Danh mục** (một, bắt buộc),
  **Nhãn** (nhiều, tuỳ chọn).
- Mọi chuỗi qua l10n; viết tiếng Việt trước.

## 8. Quản lý thay đổi

- Đổi token: sửa `tokens.json` → `node scripts/build.mjs` → `pnpm check` xanh → PR có task `DS-…`.
- Thêm component: đặt trong `apps/mobile/lib/core/widgets/`, chỉ đọc token. Không hex rời trong `lib/features`.
- Quyết định cấu trúc token: [ADR 012](../architecture/adr/012-design-tokens-v2.md).
