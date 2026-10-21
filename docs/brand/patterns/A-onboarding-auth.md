# Nhóm A — Onboarding và tài khoản

Trạng thái: **chốt thiết kế 2026-10-21**, chưa code. Task: `DS-P2-004`.
Canvas: trang **05 · Patterns**, hai hàng A1 và A2
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md). Ảnh tham chiếu: `references/09`–`13`, `17`.

## Nguyên tắc riêng cho nhóm này

- **Chữ ngắn:** tiêu đề tối đa khoảng 6 từ, dòng phụ tối đa một dòng hoặc bỏ hẳn.
- **Không đưa chi tiết kỹ thuật lên UI:** không độ dài mã, không danh sách điều kiện, không nhãn "Bước x · Bảo mật".
- **Không hỏi tiền trước khi có tài khoản.** Số dư là bước không bắt buộc, sau khi tạo tài khoản.
- **Logo chỉ ở splash.** Các màn dùng minh hoạ nét vẽ tay hoặc mảnh UI thật của app.
- Mỗi câu hỏi phải được dùng để cá nhân hoá; câu không dùng thì bỏ.

## A1 · Onboarding

```
Mở app → Welcome → Mục tiêu → Thói quen → Ngân sách tháng → Tạo tài khoản → Thiết lập tài chính → Trang chính lần đầu
```

| # | Màn | Tiêu đề / nội dung | Thành phần | Câu trả lời dùng để |
|---|---|---|---|---|
| 1 | Welcome | "Tiền rõ ràng. Sống nhẹ nhàng." · "Ghi chi tiêu chỉ vài giây mỗi ngày." | Minh hoạ từ thẻ số dư, 2 dòng giao dịch, nút +. Nút "Bắt đầu", link "Đăng nhập" | — |
| 2 | Mục tiêu | "Bạn muốn cải thiện điều gì?" · "Chọn tối đa 2." | 6 thẻ chọn 2 cột: Theo dõi chi tiêu (receipt), Tiết kiệm nhiều hơn (piggy bank), Chi đúng ngân sách (wallet), Quản lý khoản nợ (credit card), Lập quỹ dự phòng (shield), Hiểu rõ tài chính (chart). Đủ 2 thì thẻ còn lại mờ | Thứ tự khối trên trang chính |
| 3 | Thói quen | "Bạn đang quản lý tiền thế nào?" + "Bao lâu bạn xem lại chi tiêu?" | Radio dạng thẻ: ghi tay · Excel/Sheets · app khác · chưa theo dõi. Chip: mỗi ngày · mỗi tuần · mỗi tháng · hầu như không | Mức gợi ý cho người mới; mời nhập dữ liệu (sau này); nhịp tổng kết |
| 4 | Ngân sách tháng | "Mỗi tháng bạn định chi bao nhiêu?" | Số tiền lớn + chọn tiền tệ, gợi ý 5tr/10tr/15tr/20tr, bàn phím số, "Thiết lập sau" | Ngân sách tháng (`BE-P2-E02`) |
| 5 | Tạo tài khoản | "Lưu kế hoạch của bạn" · "Để không mất dữ liệu khi đổi máy." | Minh hoạ nét vẽ "tự do tài chính". Nút Google (nền nhạt), Apple (ink), email (nền nhạt). "Đã có tài khoản? Đăng nhập", điều khoản | — |
| 6 | Thiết lập tài chính | "Tiền của bạn ở đâu?" · "Thêm ví và số dư. Ước chừng là đủ." | 4 dòng loại ví, mỗi dòng "+ Thêm" hoặc số dư đã nhập. "Bỏ qua" ở góc, "Xong" | Tạo ví + số dư ban đầu |
| 7 | Trang chính lần đầu | "Chào Minh" + thẻ số dư + "Bắt đầu nào 1/3" | Checklist: ✓ Tạo ví · Ghi khoản chi đầu tiên (nút "Ghi ngay") · Khoá app bằng PIN. Trống: "Giao dịch sẽ hiện ở đây" | — |

Bước 2–4 có thanh tiến độ `1/3 … 3/3`, nút quay lại, "Để sau" bên trái và "Tiếp tục" (ink) bên phải.

## A2 · Tài khoản và bảo mật

| # | Màn | Nội dung |
|---|---|---|
| 1 | Đăng nhập | Tiêu đề giữa. Ô email + ô mật khẩu (có mắt) trên cùng một màn. "Quên mật khẩu?" gạch chân ở giữa. Nút "Đăng nhập". "hoặc" → Google, Apple. "Chưa có tài khoản? Đăng ký" |
| 2 | Tạo tài khoản bằng email | Ô email + mật khẩu, thanh độ mạnh 3 nấc. Không có ô nhập lại (dùng nút mắt) |
| 3 | Xác nhận email | "Kiểm tra email" · "Nhấn link trong thư gửi tới …". Nút "Mở ứng dụng Mail", "Gửi lại" |
| 4 | Mã PIN | "Đặt mã PIN" · "6 số để mở khoá Freeva." 6 chấm + bàn phím số |
| 5 | Face ID | "Dùng Face ID?" · "Nhanh hơn nhập PIN." "Dùng Face ID" / "Không phải bây giờ" |
| 6 | Quên mật khẩu | "Quên mật khẩu?" · "Nhập email, Freeva gửi link đặt lại." |
| 7 | Mật khẩu mới | Mở từ link trong email: chip "Đã xác nhận …", ô mật khẩu mới + độ mạnh, "Lưu và đăng nhập" |

Mở khoá hằng ngày: màn Mở khoá ở hàng mẫu (avatar chữ cái, "Chào Minh", "Nhập mã PIN", nút Face ID trên bàn phím).

**Luồng:** đăng ký email đi 5 → 2 → 3 → 4 → 5 (PIN, Face ID) → A1.6. Google/Apple đi thẳng A1.5 → A1.6; khoá app được nhắc ở checklist trang chính.

## Thành phần mới (bổ sung vào design system)

- **Thẻ chọn (selectable card):** nền trắng viền `border.default`; chọn = nền `tint.blue` (`#EEF2FD`), viền 1.5 `action.primary`, dấu tích tròn `action.primary`. Dạng lưới 2 cột (có icon) hoặc dạng dòng (radio/checkbox).
- **Ô nhập viên thuốc (auth input):** cao 54, bo full, icon đầu dòng (thư, khoá), nhãn ẩn cho trình đọc màn hình, mắt ẩn/hiện. Chỉ dùng ở màn tài khoản; form dữ liệu giữ ô có nhãn trong.
- **Nút đăng nhập mạng xã hội:** cao 54, không viền. Google nền `bg.subtle`, Apple nền `action.ink`.
- **Thanh độ mạnh mật khẩu:** 3 đoạn, màu `status.success`, nhãn "Khá tốt" / "Rất chắc chắn".
- **Thanh tiến độ onboarding:** 6 px, `action.primary` trên `border.default`, kèm "1/3".
- **Minh hoạ nét vẽ tay:** xem [design-system.md](../design-system.md#icon-và-minh-hoạ).

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Link xác nhận email và đặt lại mật khẩu mở thẳng app | Backend hiện gửi mã 64 ký tự; cần deep link / universal link. |
| Google, Apple trên mobile | ADR 010 đã có, mobile chưa làm. |
| Ngân sách tháng (A1.4) | Thuộc `BE-P2-E02`. Nếu onboarding ra trước: lưu tạm con số, áp khi có ngân sách; hoặc ẩn màn 4. |
| PIN không còn bắt buộc ngay sau đăng nhập | App hiện bắt đặt PIN; đổi thành bước gợi ý. |
| Bỏ ô "nhập lại mật khẩu" | App hiện yêu cầu xác nhận hai lần. |
| Câu trả lời A1.2–A1.3 | Lưu vào hồ sơ (cần field mới) để cá nhân hoá. |
| Chế độ khách | **Chưa làm** — cần dữ liệu cục bộ và gộp khi đăng ký; quyết định sau. |
| Copy l10n | Toàn bộ chuỗi trên thay chuỗi `auth*`, `onboarding*` hiện có trong `app_vi.arb` / `app_en.arb`. |
