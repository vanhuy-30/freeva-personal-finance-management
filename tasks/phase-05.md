# Phase 5 — epic

[phase-05.md](../docs/product/phases/phase-05.md). Không epic nào thuộc product v1.

Phạm vi chốt 2026-11-11 (chủ dự án):

- Nhập sao kê ngân hàng (`BE-P5-E01`) không làm.
- OCR (`BE-P5-E02`) và Ask Freeva (`BE-P5-E05`) chuyển sang [Phase 8](phase-08.md) vì chưa chốt hướng AI.
- Gợi ý danh mục, insight, dự báo chi, what-if tính bằng quy tắc và số liệu từ sổ; không gửi dữ liệu ra ngoài, không gọi model.
- Số và cấu hình mang nghĩa sản phẩm (ngưỡng, giới hạn, danh sách, bật/tắt) không hardcode trong app: nằm ở server, sửa trên web admin. Áp dụng cho cả phần đã làm ở Phase 0–4 (`BE-P5-001` / `MOB-P5-001`).
- Mỗi màn gợi ý có nút báo "Không đúng", lưu vào bảng `Feedback` có sẵn.
- Màn mới có board thiết kế trước khi code (`DS-P5-001`). Chưa paywall; quyền Premium là việc của Phase 7.

Thứ tự: `BE-P5-E08` → `WA-P5-001` → `MOB-P5-E08` → `BE-P5-001` / `MOB-P5-001` → `DS-P5-001` → `PRD-P5-E01` → `E03` → `E04` → `E07` → `E06`.

### BE-P5-E08 — Cờ và cấu hình phía server
- Status: todo
- Module: 18, 26
- Gate: post-v1
- Depends: MOB-P0-003
- DoD:
  - **Cờ:** `category_suggest`, `insights`, `forecast` (dùng cho cả `E06` và `E07`). Cờ của phase sau thêm khi làm phase đó (`bank_connect`, `family`, `ocr`, `ai_chat`). Bật theo môi trường, danh sách user (UUID) hoặc phần trăm; phần trăm chia theo hash ổn định của user id để một người không bật/tắt qua lại.
  - **Cấu hình:** mỗi khóa có kiểu, mặc định, giới hạn min/max và mô tả; giá trị sai kiểu hoặc ngoài giới hạn bị từ chối khi lưu. Danh sách khóa ban đầu là kết quả rà soát ở `BE-P5-001`.
  - **API:** `GET /api/v1/app-config` trả cờ đã tính cho user và cấu hình, kèm `version` để app biết có thay đổi. Backend đọc cùng nguồn khi kiểm tra quy tắc, không giữ bản sao số trong code.
  - Cờ tắt thì API tương ứng trả `403 FEATURE_DISABLED`, không chạy ngầm.
  - Mỗi lần đổi cờ hoặc cấu hình ghi audit (người sửa, giá trị trước và sau). Không chứa dữ liệu tài chính của user.

### WA-P5-001 — Màn cờ và cấu hình trên web admin
- Status: todo
- Module: 26
- Gate: post-v1
- Depends: BE-P5-E08, WA-P0-002
- DoD: staff xem và sửa cờ (môi trường, danh sách user, phần trăm) và từng khóa cấu hình, thấy mô tả, mặc định, giới hạn và lần sửa gần nhất. Hiện giá trị cũ và mới, xác nhận trước khi lưu. Lỗi kiểm tra hiện tại ô nhập. Mọi thay đổi có audit. Auth single-staff P0 vẫn phải thay trước production (đã ghi ở `WA-P0-002`).

### MOB-P5-E08 — App đọc cờ và cấu hình từ server
- Status: todo
- Module: 18, 26
- Gate: post-v1
- Depends: BE-P5-E08
- DoD: thay `LocalFeatureFlagService` bằng bản đọc `GET /app-config`. Tải khi đăng nhập và khi mở app, lưu bản gần nhất trên máy; mỗi giờ hoặc khi `version` đổi thì tải lại. Không có bản nào (chưa từng tải được) thì cờ coi là tắt và màn cần cấu hình hiện trạng thái "Không tải được, thử lại" thay vì dùng số đoán. Overlay local chỉ có ở bản dev.

### BE-P5-001 / MOB-P5-001 — Chuyển số và cấu hình đang hardcode lên server
- Status: todo
- Module: 26 và các module có giá trị bị rà ra
- Gate: post-v1
- Depends: BE-P5-E08, MOB-P5-E08
- DoD: mọi giá trị trong danh sách rà soát dưới đây đọc từ `app-config` (hoặc API nghiệp vụ đã có) thay vì hằng số trong app. Backend kiểm tra cùng giá trị đó. Đổi giá trị trên web admin thì app có hiệu lực sau lần tải cấu hình kế tiếp, không cần phát hành bản mới. Không đổi hành vi mặc định: giá trị ban đầu trên server bằng giá trị hiện tại.
- Danh sách rà soát (2026-11-11, `apps/mobile/lib`):
  - **Chỉ có trên app, đưa lên cấu hình:**
    - Ngân sách: các mốc cảnh báo cho chọn 70/80/90/100.
    - Dự báo số dư: lựa chọn 3/6/12 tháng.
    - Trả góp: kỳ hạn cho chọn 3/6/9/12, mặc định 6.
    - Định kỳ: nhắc trước 0/1/3/7 ngày.
    - Thẻ tín dụng: mức dùng cao 70%, nguy hiểm 90%.
    - "Sắp đến hạn": thẻ 7 ngày, cho mượn/đi mượn 14 ngày (server nhắc ở 3 ngày).
    - Onboarding: gợi ý thu nhập 10/15/25/40 triệu, phần tiết kiệm 20% trong gợi ý ngân sách, tối đa 2 mục tiêu, danh sách loại mục tiêu cho chọn.
    - Mặc định khoảng của tài sản ròng và biểu đồ đầu tư (6 tháng).
    - Báo cáo: khoảng nhanh 7/30 ngày và quý, số dòng top 3, số giao dịch gần đây trên Home (3).
    - Ngày mục tiêu: mặc định +30 ngày, tối đa +60 năm.
    - Bước phút của giờ nhắc ghi chi (15 phút).
    - Quy tắc mức "rất mạnh" của mật khẩu.
    - Số lần nhập sai PIN trước khi đăng xuất (5). Độ dài PIN 6 số giữ trong code: đổi từ xa làm hỏng PIN đã đặt (chốt 2026-11-11).
  - **Server đã có hằng số, app giữ bản sao:** độ dài mật khẩu và email, độ dài tên/ghi chú/nhãn, số nhãn tối đa, giới hạn ngân sách (tối đa 4 mốc, 1–100), ngày đầu kỳ 1–28, dự báo 1–12 tháng, trả góp 2–60 kỳ, giới hạn khoản vay và định kỳ, giới hạn nhập CSV (2 000 dòng, 1 000 000 ký tự) và xuất CSV (50 000 dòng), khoảng báo cáo tối đa, các khoảng tài sản ròng, loại và đơn vị đầu tư, loại và chủ đề phản hồi. App đọc từ `app-config` sinh từ cùng hằng số ở backend.
  - **Server đã trả mà app bỏ qua:** `categories/options.iconTokens` (app dùng nhóm icon và icon chọn nhanh tự viết), `GET goals/presets` (app dùng `goal_look.dart`). Nhóm icon và icon chọn nhanh chuyển lên server.
  - **Đang lệch với server (chốt 2026-11-11):** giờ nhắc ghi chi mặc định lấy `21:00` theo board (server đang `20:00`, sửa default kèm migration). Độ dài tên hiển thị lấy 60 theo server (app đang 50).
  - **Để sang Phase 7:** nội dung FAQ và điều khoản/chính sách bảo mật đang viết trong app. Chuyển lên server cùng màn quản trị FAQ của `WA-P7-E01`; nội dung pháp lý còn chờ luật sư.
  - **Tiền tệ:** quy tắc `VND ? 0 : 2` chữ số lẻ, ký hiệu `₫` và mặc định `VND` rải ở khoảng 30 file. Dùng `minorDigits` server đã trả và thêm ký hiệu vào bảng `Currency`.
  - **Bật/tắt viết cứng:** Google/Apple ("Sắp có"), sửa hồ sơ, các dòng thông báo "Sắp có" bỏ qua cờ `available` của server. Chuyển thành cờ.
  - **Copy chứa số:** "80% và 100%", "8 ký tự", "6 số", "2 000 dòng", "50 000 dòng"… dựng chuỗi từ giá trị cấu hình.
  - **Không chuyển (chốt 2026-11-11):** enum nghiệp vụ mà app phải có code riêng cho từng giá trị (loại ví, loại giao dịch, đơn vị lặp), design token, khoảng cách, thời gian animation. Phiên bản app đọc từ gói cài đặt thay vì hằng `0.0.1+1`.

### DS-P5-001 — Thiết kế màn Phase 5
- Status: todo
- Module: 5, 14, 18, 24
- Gate: post-v1
- Depends: —
- DoD: board cho gợi ý danh mục (màn ghi chi, nhập CSV), thẻ insight trên Home (dưới thẻ soát tháng) và màn phân tích, dự báo chi cuối tháng, ngày đạt mục tiêu, what-if trên chi tiết mục tiêu, cài đặt "Gợi ý tự động" (tắt, xóa dữ liệu đã học), nút "Không đúng". Copy ngắn, không chi tiết kỹ thuật.

### PRD-P5-E01 / MOB-P5-002 — Tắt gợi ý tự động và xóa dữ liệu đã học
- Status: todo
- Module: 18, 21
- Gate: post-v1
- Depends: BE-P5-E08
- DoD: các gợi ý của Phase 5 chạy trên server của Freeva, không gửi dữ liệu ra ngoài: mặc định bật, user tắt được trong Cài đặt. Tắt thì API gợi ý và insight không trả kết quả cho user đó. User xóa được mapping merchant → danh mục đã học và insight đã lưu. Xuất dữ liệu có các mục này; xóa tài khoản xóa luôn. Đồng ý dùng AI bên ngoài là việc của `PRD-P8-E02`.
- Note: 2026-11-11 bỏ phụ thuộc `BE-P5-E03` (phụ thuộc vòng tròn); phần đồng ý AI bên ngoài chuyển sang Phase 8.

### BE-P5-E03 / MOB-P5-E03 — Gợi ý danh mục
- Status: todo
- Module: 18, 5
- Gate: post-v1
- Depends: BE-P1-006, BE-P1-011, BE-P5-E08, PRD-P5-E01
- DoD:
  - Từ merchant hoặc ghi chú đề xuất một danh mục và độ tin cậy, theo thứ tự: mapping user đã chấp nhận, lịch sử giao dịch của chính user, danh sách merchant chung.
  - Danh sách merchant chung (Grab, Shopee, Lazada, WinMart, Circle K, Highlands, The Coffee House…) nằm trong cấu hình, sửa được trên web admin.
  - Độ tin cậy là tỷ lệ khớp trong lịch sử; dưới ngưỡng thì không hiện. Ngưỡng là cấu hình (mặc định 60%).
  - Dùng ở màn ghi chi và màn nhập CSV. User sửa được; chấp nhận thì nhớ mapping. Không tự lưu giao dịch.
  - Server đếm tỷ lệ chấp nhận và tỷ lệ sửa (không phụ thuộc nhà cung cấp analytics). Có nút "Không đúng".
  - Cờ `category_suggest` tắt hoặc user tắt ở `PRD-P5-E01` thì API không đề xuất.

### BE-P5-E04 / MOB-P5-E04 — Insight cơ bản
- Status: todo
- Module: 18
- Gate: post-v1
- Depends: BE-P1-007, BE-P2-E02, BE-P3-E01, BE-P5-E08, PRD-P5-E01
- DoD:
  - Bốn dạng, câu theo mẫu có sẵn, mỗi số lấy từ báo cáo, ngân sách hoặc mục tiêu: xu hướng chi, danh mục tăng hoặc giảm, rủi ro vượt ngân sách, giao dịch lệch khỏi mức thường.
  - "Lệch khỏi mức thường": lớn hơn N lần trung bình M tháng của danh mục đó. Cần ít nhất K tháng dữ liệu mới nêu con số. N, M, K là cấu hình (mặc định 2, 3, 2).
  - Chỉ tính theo tiền tệ của hồ sơ; giao dịch loại tiền khác không đưa vào.
  - Home hiện một insight dưới thẻ soát tháng, kèm CTA xem phân tích. Chưa mở tab Insights.
  - Không đủ dữ liệu thì câu không có số. Không bịa phần trăm. Có nút "Không đúng".
  - Cờ `insights` tắt hoặc user tắt thì ẩn thẻ.

### BE-P5-E06 / MOB-P5-E06 — Dự báo chi cuối tháng và ngày đạt mục tiêu
- Status: todo
- Module: 18, 14
- Gate: post-v1
- Depends: BE-P1-007, BE-P2-E02, BE-P3-E01, BE-P5-E08
- DoD:
  - Khác `BE-P3-E04` (chỉ chiếu khoản định kỳ): dùng tốc độ chi thực tế của tháng đang chạy để dự báo chi đến cuối tháng, so với ngân sách, kèm mức rủi ro thấp / vừa / cao. Ranh giới các mức là cấu hình.
  - Ngày đạt mục tiêu theo mức góp trung bình M tháng gần nhất (M là cấu hình, mặc định 3). Chưa góp lần nào thì nói chưa đủ dữ liệu.
  - Màn hình ghi rõ đây là dự đoán, không phải số đã xảy ra, và nêu cách tính. Không có quỹ đạo tiết kiệm dài hạn.
  - Chỉ tính theo tiền tệ của hồ sơ. Có nút "Không đúng". Cờ `forecast`.

### BE-P5-E07 / MOB-P5-E07 — What-if
- Status: todo
- Module: 18, 9
- Gate: post-v1
- Depends: BE-P3-E01, BE-P5-E08
- DoD: từ chi tiết một mục tiêu, user nhập một thay đổi chi bằng form (ví dụ giảm một danh mục X đồng mỗi tháng) và thấy số tiết kiệm thêm mỗi tháng, mỗi năm, và mục tiêu đó đạt sớm hơn bao nhiêu (dùng công thức của `POST /goals/preview`). Không ghi vào sổ. Cờ `forecast`.

### BE-P5-E01 / MOB-P5-E01 — Import sao kê ngân hàng Excel, PDF
- Status: wont — chủ dự án chốt 2026-11-11 không cần. Nhập CSV từ app khác đã có ở `BE-P3-011`.

### MOB-P5-E02 / BE-P5-E02 — OCR hóa đơn
- Status: wont — chuyển sang `BE-P8-E01` / `MOB-P8-E01` (2026-11-11), chờ chốt hướng AI.

### BE-P5-E05 / MOB-P5-E05 — Ask Freeva
- Status: wont — chuyển sang `BE-P8-E03` / `MOB-P8-E03` (2026-11-11), chờ chốt hướng AI.
