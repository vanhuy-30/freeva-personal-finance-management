# Nhóm A — Onboarding và tài khoản

Trạng thái: **chốt thiết kế 2026-10-21, sửa luồng 2026-10-23** (tạo tài khoản trước câu hỏi, xác nhận email bỏ qua được, PIN nhập lại, quy tắc mật khẩu), code A1 (tài khoản và bảo mật) và A2a (Welcome, Tạo tài khoản, ba câu hỏi) và A2b (Thiết lập tài chính, checklist trang chính, tên ở màn Mở khoá) xong 2026-10-23. Task: `DS-P2-004`.
Canvas: trang **05 · Patterns**, hai hàng A1 và A2
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- **Chữ ngắn:** tiêu đề tối đa khoảng 6 từ, dòng phụ tối đa một dòng hoặc bỏ hẳn.
- **Không đưa chi tiết kỹ thuật lên UI:** không độ dài mã, không nhãn "Bước x · Bảo mật". Ngoại lệ do product owner chốt 2026-10-23: điều kiện mật khẩu hiện thành danh sách tự tick khi gõ (A2.2, A2.8).
- **Tạo tài khoản trước, câu hỏi sau** (2026-10-23): chưa có chế độ khách nên câu trả lời A1.3–A1.5 cần tài khoản để lưu vào hồ sơ. Người đăng nhập lại không gặp các câu này.
- **Không hỏi tiền sớm.** Ngân sách và số dư là bước không bắt buộc, đều có "Để sau" / "Bỏ qua".
- **Logo chỉ ở splash.** Các màn dùng minh hoạ nét vẽ tay hoặc mảnh UI thật của app.
- Mỗi câu hỏi phải được dùng để cá nhân hoá; câu không dùng thì bỏ.

## A1 · Onboarding

```
Mở app → Welcome → Tạo tài khoản → (email: A2.2 → A2.3, bỏ qua được) → Mục tiêu → Thói quen
→ Ngân sách tháng → Thiết lập tài chính → Đặt PIN → Nhập lại PIN → Face ID → Trang chính lần đầu
```

| # | Màn | Tiêu đề / nội dung | Thành phần | Câu trả lời dùng để |
|---|---|---|---|---|
| 1 | Welcome | "Tiền rõ ràng. Sống nhẹ nhàng." · "Ghi chi tiêu chỉ vài giây mỗi ngày." | Minh hoạ từ thẻ số dư, 2 dòng giao dịch, nút +. Nút "Bắt đầu" (→ 2), link "Đăng nhập" | — |
| 2 | Tạo tài khoản | "Tạo tài khoản Freeva" · "Dữ liệu được lưu an toàn, đổi máy không mất." | Minh hoạ nét vẽ "tự do tài chính". Nút Google (nền nhạt), Apple (ink), email (nền nhạt). "Đã có tài khoản? Đăng nhập", điều khoản | — |
| 3 | Mục tiêu | "Bạn muốn cải thiện điều gì?" · "Chọn tối đa 2." | 6 thẻ chọn 2 cột: Theo dõi chi tiêu (receipt), Tiết kiệm nhiều hơn (piggy bank), Chi đúng ngân sách (wallet), Quản lý khoản nợ (credit card), Lập quỹ dự phòng (shield), Hiểu rõ tài chính (chart). Đủ 2 thì thẻ còn lại mờ. Không có nút quay lại (đã đăng nhập) | Thứ tự khối trên trang chính |
| 4 | Thói quen | "Bạn đang quản lý tiền thế nào?" + "Bao lâu bạn xem lại chi tiêu?" | Radio dạng thẻ: ghi tay · Excel/Sheets · app khác · chưa theo dõi. Chip: mỗi ngày · mỗi tuần · mỗi tháng · hầu như không | Mức gợi ý cho người mới; mời nhập dữ liệu (sau này); nhịp tổng kết |
| 5 | Ngân sách tháng | "Mỗi tháng bạn định chi bao nhiêu?" | Số tiền lớn + chọn tiền tệ, gợi ý 5tr/10tr/15tr/20tr, bàn phím số, "Thiết lập sau" | Ngân sách tháng (`BE-P2-E02`) |
| 6 | Thiết lập tài chính | "Tiền của bạn ở đâu?" · "Thêm ví và số dư. Ước chừng là đủ." | 4 dòng loại ví, mỗi dòng "+ Thêm" hoặc số dư đã nhập. "Bỏ qua" ở góc, "Xong" (→ A2.4) | Tạo ví + số dư ban đầu |
| 7 | Trang chính lần đầu | "Chào Minh" + thẻ số dư + "Bắt đầu nào 1/3" | Checklist: ✓ Tạo ví · Ghi khoản chi đầu tiên (nút "Ghi ngay") · Khoá app bằng PIN (khi đã bỏ qua PIN). Trống: "Giao dịch sẽ hiện ở đây" | — |

Bước 3–5 có thanh tiến độ `1/3 … 3/3`, nút quay lại (trừ bước 3), "Để sau" bên trái và "Tiếp tục" (ink) bên phải.

## A2 · Tài khoản và bảo mật

| # | Màn | Nội dung |
|---|---|---|
| 1 | Đăng nhập | Tiêu đề giữa. Ô email + ô mật khẩu (có mắt) trên cùng một màn. "Quên mật khẩu?" gạch chân ở giữa. Nút "Đăng nhập". "hoặc" → Google, Apple. "Chưa có tài khoản? Đăng ký" (→ A1.2) |
| 2 | Tạo tài khoản bằng email | Ô email, mật khẩu, **nhập lại mật khẩu** (đều có mắt), thanh độ mạnh 3 nấc. Danh sách tự tick: "Ít nhất 12 ký tự" · "Có cả chữ và số" (bắt buộc) · "Thêm ký hiệu như ! @ # để mạnh hơn" (gợi ý) · "Hai mật khẩu khớp nhau". **Checkbox** "Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Freeva." Nút "Tạo tài khoản" |
| 3 | Xác nhận email | "Xác nhận email" · "Freeva đã gửi link xác nhận tới …". Thẻ "Email đã xác nhận giúp bạn": lấy lại mật khẩu khi quên · nhận cảnh báo khi có đăng nhập lạ · không lỡ thông báo quan trọng về tài khoản. Nút "Xong" (→ A1.3; không mở app Mail từ Freeva), "Gửi lại". **Không bắt buộc:** chữ "Chưa xác nhận vẫn dùng app bình thường. Bạn có thể xác nhận sau ở Cá nhân." Không có nút quay lại: tài khoản đã tạo, quay lại sẽ thành đăng xuất (owner 2026-10-27). |
| 4 | Đặt mã PIN | Quay lại · "Để sau" (→ A1.7). "Đặt mã PIN" · "6 số để mở khoá Freeva trên máy này." 6 chấm + bàn phím số, nút "Tiếp tục" |
| 5 | Nhập lại mã PIN | Quay lại · "Để sau". "Nhập lại mã PIN" · "Nhập lại 6 số vừa đặt để chắc chắn." 6 chấm, "Không khớp sẽ được nhập lại từ đầu.", nút "Xác nhận" |
| 6 | Face ID | "Thiết lập Face ID" · "Mở khoá Freeva bằng khuôn mặt, nhanh hơn nhập PIN." "Thiết lập Face ID" / "Để sau" (→ A1.7) |
| 7 | Quên mật khẩu | "Quên mật khẩu?" · "Nhập email, Freeva gửi link đặt lại." |
| 8 | Mật khẩu mới | Mở từ link trong email: chip "Đã xác nhận …", ô mật khẩu mới + nhập lại, độ mạnh và cùng danh sách điều kiện như màn 2, "Lưu và đăng nhập" |

Mở khoá hằng ngày: màn Mở khoá ở hàng mẫu (avatar chữ cái, "Chào Minh", "Nhập mã PIN", nút Face ID trên bàn phím).

**Luồng:** đăng ký email đi A1.2 → A2.2 → A2.3 → A1.3 → … → A1.6 → A2.4 → A2.5 → A2.6 → A1.7. Google/Apple đi A1.2 → A1.3. Mọi cách đăng ký đều qua PIN và Face ID sau A1.6; bỏ qua thì checklist trang chính nhắc "Khoá app bằng PIN". Đăng nhập lại vào thẳng app, không qua A1.3–A1.5.

**Mật khẩu (chốt 2026-10-23):** mật khẩu mới 12–128 ký tự, có ít nhất một chữ cái và một chữ số (mọi bảng chữ); ký hiệu chỉ là gợi ý. Đăng nhập chỉ kiểm tra độ dài để mật khẩu cũ dùng tiếp. Đã làm ở backend và mobile (`DS-P2-004`).

## Thành phần mới (bổ sung vào design system)

- **Thẻ chọn (selectable card):** nền trắng viền `border.default`; chọn = nền `tint.blue` (`#EEF2FD`), viền 1.5 `action.primary`, dấu tích tròn `action.primary`. Dạng lưới 2 cột (có icon) hoặc dạng dòng (radio/checkbox).
- **Ô nhập viên thuốc (auth input):** cao 54, bo full, icon đầu dòng (thư, khoá), nhãn ẩn cho trình đọc màn hình, mắt ẩn/hiện. Chỉ dùng ở màn tài khoản; form dữ liệu giữ ô có nhãn trong.
- **Nút đăng nhập mạng xã hội:** cao 54, không viền. Google nền `bg.subtle`, Apple nền `action.ink`.
- **Thanh độ mạnh mật khẩu:** 3 đoạn, màu `status.success`, nhãn "Khá tốt" / "Rất chắc chắn".
- **Danh sách điều kiện mật khẩu:** mỗi dòng có vòng tròn 18 (đạt: nền `status.successBg` + dấu tích; chưa: viền `border.default`), chữ 13; `aria-live` để đọc khi thay đổi; ô mật khẩu trỏ `aria-describedby` tới danh sách.
- **Checkbox đồng ý:** ô 22 bo 7, chọn = nền `action.primary` + dấu tích trắng; link Điều khoản và Chính sách gạch chân.
- **Thanh tiến độ onboarding:** 6 px, `action.primary` trên `border.default`, kèm "1/3".
- **Minh hoạ nét vẽ tay:** xem [design-system.md](../design-system.md#icon-và-minh-hoạ).

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Link xác nhận email và đặt lại mật khẩu mở thẳng app | Chốt 2026-10-23: bỏ nhập mã 64 ký tự trên UI; backend gửi một link, người dùng bấm trong mail. Cần deep link / universal link (task riêng). |
| Google, Apple trên mobile | ADR 010 đã có, mobile chưa làm. |
| Ngân sách tháng (A1.5) | Xong: `PUT /budgets/current` nếu chưa có ngân sách, không thì giữ `budgetDraftMinor` (`BE-P2-E02`). |
| PIN không còn bắt buộc ngay sau đăng nhập | App hiện bắt đặt PIN; đổi thành bước gợi ý có "Để sau", luôn có màn nhập lại PIN. |
| Ô "nhập lại mật khẩu" | Giữ (2026-10-23), như app hiện tại. |
| Quy tắc chữ + số | Xong ở backend + mobile (`DS-P2-004`, 2026-10-23). |
| Xác nhận email không bắt buộc | Backend đã cho đăng nhập trước khi xác nhận (ADR 009); mobile cần cho đi tiếp sau A2.3 và nơi xác nhận lại trong Cá nhân. |
| Lưu đồng ý điều khoản | Cần ghi lại thời điểm và phiên bản điều khoản khi đăng ký email (Google/Apple: dòng chữ ở A1.2). |
| Câu trả lời A1.3–A1.4 | Xong (A2a): `User.onboardingGoals/trackingHabit/reviewCadence`, `PATCH /api/v1/profile/onboarding`, mọi trường tuỳ chọn. Mục tiêu "Quản lý khoản nợ" đưa khối Thẻ tín dụng lên đầu Tổng quan; các mục tiêu khác chưa có khối (chưa thiết kế, owner chốt giữ nguyên 2026-10-29). Chưa có trong `GET /account/export` (`BE-P2-012`). |
| Chế độ khách | **Chưa làm** — cần dữ liệu cục bộ và gộp khi đăng ký; quyết định sau. |
| Copy l10n | Toàn bộ chuỗi trên thay chuỗi `auth*`, `onboarding*` hiện có trong `app_vi.arb` / `app_en.arb`. |
