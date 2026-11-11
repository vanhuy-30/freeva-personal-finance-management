# Nhóm R — Gợi ý danh mục · S — Đáng chú ý và dự báo chi · T — Ngày dự kiến đạt mục tiêu · U — Gợi ý tự động

Trạng thái: **chốt thiết kế 2026-11-11**, chưa code. Task: `DS-P5-001` (thiết kế); code ở `BE-P5-E03` / `MOB-P5-E03` (R), `BE-P5-E04` / `MOB-P5-E04` (S.1, S.2), `BE-P5-E06` / `MOB-P5-E06` (S.3, T), `PRD-P5-E01` / `MOB-P5-002` (U).
Canvas: trang **09 · Phase 5** (`p5`). Spec chung: [design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Mọi số lấy từ sổ của người dùng, tính bằng quy tắc; không gửi dữ liệu ra ngoài.
- **Không có nút "Không đúng"** (chủ dự án 2026-11-11): insight là số thật từ sổ. Gợi ý danh mục sai thì người dùng chọn danh mục khác như thường, app tính đó là một lần sửa.
- **Không có what-if** (chủ dự án 2026-11-11): chỉ đưa insight và dự báo, không có màn "Thử bớt chi".
- Mỗi insight có một hình nhỏ đi kèm (thanh so sánh hoặc thanh ngân sách); không chỉ có một câu.
- Dự báo luôn ghi đó là dự đoán, chưa phải số đã chi.
- Không gợi ý nào tự lưu giao dịch hay tự sửa sổ.
- Insight tính mỗi lần xem, không lưu trên server (2026-11-11): "dữ liệu đã học" chỉ là danh sách cửa hàng đã nhớ.

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| R.1 | Ghi chi · gợi ý danh mục | Như C2.3. Gõ tên cửa hàng (hoặc ghi chú) thì dưới ô hiện thẻ nền `blue.50` viền `#DCE4FA`: icon danh mục 36, "Xếp vào Cà phê?", dòng phụ "Như 8 lần trước ở đây", nút viên thuốc đen "Dùng" | "Dùng" đổi dòng Danh mục và nhớ cho lần sau. Gợi ý từ danh sách cửa hàng chung: bỏ dòng phụ. Dưới ngưỡng tin cậy: không hiện thẻ |
| R.2 | Nhập giao dịch · lọc Gợi ý | Như O.7, thêm chip "Gợi ý 18" (icon lấp lánh). Dòng gợi ý "Danh mục đoán theo cửa hàng. Chạm để đổi." Danh mục đoán hiện màu `blue.600` có icon lấp lánh 12 | Khoản tệp đã có danh mục: giữ nguyên, không gợi ý. Bấm "Nhập" là đồng ý các gợi ý còn lại |
| R.3 | Đổi danh mục (sheet, trên R.2) | Tên cửa hàng, "03/11 · 45.000 · Tiền mặt". **GỢI Ý**: thẻ chọn đang tích. **HOẶC CHỌN DANH MỤC KHÁC**: lưới 2 cột thẻ chọn + "Tất cả". Công tắc "Áp dụng cho 6 khoản ở đây". "Xong" | Chọn danh mục khác tính là sửa |
| S.1 | Tổng quan · đáng chú ý | Dưới thẻ soát tháng một thẻ: nhãn "Đáng chú ý" (icon bóng đèn, chữ `status.warning`) và "Xem cả 4 ›", câu insight 15/600, hai thanh so sánh "Tháng này" / "Tháng trước" | Chạm cả thẻ mở S.2. Chỉ một insight, xếp đầu S.2. Tắt Gợi ý tự động hoặc cờ `insights` tắt thì ẩn thẻ |
| S.2 | Phân tích | Quay lại · "Phân tích" · nút cài đặt (mở U.1). Thẻ dự báo chi (mở S.3): "Dự báo chi cuối tháng 11", chip rủi ro, số lớn, thanh đã chi + phần dự báo sọc + vạch ngân sách, chú thích. **ĐÁNG CHÚ Ý · 4**: mỗi insight một thẻ chạm được (icon 36, câu, mũi tên) và một hình: thanh so sánh hai dòng, hoặc thanh ngân sách. Cuối màn "Tính từ sổ của bạn, cập nhật mỗi ngày." | Bốn dạng: danh mục tăng/giảm, rủi ro vượt ngân sách, xu hướng chi, khoản lệch khỏi mức thường. Chạm mở giao dịch đã lọc, ngân sách hoặc báo cáo |
| S.3 | Dự báo chi cuối tháng | Thẻ: "Cuối tháng 11 có thể chi khoảng", chip rủi ro, số 32, "Vượt ngân sách khoảng 1.200.000", biểu đồ cộng dồn (vùng đã chi, nét đứt dự báo, đường ngân sách, chấm "Hôm nay"). Hai ô: "Trung bình mỗi ngày", "Để không vượt, mỗi ngày dưới 480.000" (nền `status.success` nhạt). **CHI NHIỀU NHẤT THÁNG NÀY**: 3 danh mục có thanh tỷ lệ. Dòng chú thích icon info "Dự đoán theo mức chi trung bình mỗi ngày từ đầu tháng, chưa phải số đã chi." | Chưa có ngân sách: bỏ chip, đường ngân sách và ô "Để không vượt". Mới đầu tháng: "Chưa đủ dữ liệu, xem lại sau vài ngày" |
| T.1 | Chi tiết mục tiêu · dự kiến | Như I.4; ô "Ngày đạt" đổi tên **"Hạn"**. Thẻ mới dưới lưới 2×2: "Với mức góp gần đây" / "Dự kiến đạt 02/2028", chip "Trễ 6 tháng"; dải mốc **Hôm nay → Hạn → Dự kiến** (đoạn tới hạn `blue.600`, đoạn trễ nét đứt `status.warning`); dòng "Góp trung bình 5.000.000 mỗi tháng trong 3 tháng qua. Góp 8.000.000 mỗi tháng để kịp hạn." | Kịp hạn: chip "Kịp hạn" xanh lá, không có đoạn trễ. Chưa góp lần nào: "Chưa đủ dữ liệu để dự kiến · Góp lần đầu để xem ngày đạt", không có dải mốc |
| U.1 | Gợi ý tự động | Một thẻ công tắc "Gợi ý tự động" · "Danh mục, phân tích, dự báo". Dòng icon khiên xanh "Chỉ tính trên sổ của bạn, không gửi ra ngoài." **CỬA HÀNG ĐÃ NHỚ · 12**: dòng cửa hàng → danh mục, nút × quên từng dòng, "Xem cả 12". Nút viền đỏ "Xoá dữ liệu đã học" | Lối vào: Cá nhân → **ỨNG DỤNG** thêm dòng "Gợi ý tự động" (icon lấp lánh, phụ "Bật"/"Tắt") và nút cài đặt ở S.2. Tắt: ẩn S.1, không gợi ý danh mục, không dự báo; danh sách đã nhớ giữ tới khi xoá. Chưa nhớ cửa hàng nào: ẩn nhóm CỬA HÀNG ĐÃ NHỚ và nút xoá. Dòng ở Cá nhân chỉ hiện khi ít nhất một cờ `category_suggest`, `insights`, `forecast` bật |
| U.2 | Xoá dữ liệu đã học (popup, trên U.1) | Icon thùng rác đỏ, "Xoá dữ liệu đã học?", "12 cửa hàng đã nhớ sẽ bị xoá. Giao dịch vẫn giữ nguyên." Huỷ · Xoá | |

## Thành phần mới

- **Thẻ gợi ý trong form:** nền `blue.50`, viền 1 `#DCE4FA`, bo 16; icon 36 trên nền trắng; nút viên thuốc đen cao 36.
- **Thanh so sánh insight:** lưới `78px 1fr 84px`: nhãn 12 muted, thanh 8 trên nền `#F1F3F8`, số 13/600 canh phải. Dòng chính `data.1` (blue 500), dòng so sánh `data.muted` (blue 100); khoản lệch dùng violet 500.
- **Thẻ insight:** icon 36 bo 12 theo loại (tăng: warning; ngân sách: danger; xu hướng: blue; khoản lệch: violet), câu 15/600 tối đa 2 dòng, mũi tên phải, hình bên dưới.
- **Dải mốc mục tiêu:** đường 4, ba chấm 14 có vòng 3, nhãn 11 muted + giá trị 13/600 dưới mỗi chấm (đầu canh trái, giữa canh giữa, cuối canh phải).
- **Biểu đồ dự báo chi:** vùng `blue.50` + nét `blue.600` 2.5 cho số đã chi, nét đứt `status.danger` 2 cho dự báo, đường ngân sách chấm `ink`.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Cờ | `category_suggest` (R), `insights` (S.1, S.2), `forecast` (S.3, T) |
| Gợi ý danh mục | API đề xuất theo cửa hàng/ghi chú trả danh mục, độ tin cậy và số lần khớp ("Như 8 lần trước"); API ghi chấp nhận / sửa; nhập CSV trả gợi ý theo dòng |
| Insight | Câu mẫu và các số cho hình (giá trị kỳ này, giá trị so sánh, hoặc đã dùng / ngân sách), đích khi chạm |
| Dự báo chi | Số dự báo, mức rủi ro, chuỗi cộng dồn theo ngày, trung bình/ngày, mức nên chi mỗi ngày, top 3 danh mục |
| Ngày dự kiến | Mức góp trung bình M tháng, tháng dự kiến, số tháng trễ/sớm so với hạn |
| Gợi ý tự động | Bật/tắt theo user, danh sách cửa hàng đã nhớ (xoá từng dòng, xoá hết) |
