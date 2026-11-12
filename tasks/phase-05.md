# Phase 5 — epic

[phase-05.md](../docs/product/phases/phase-05.md). Không epic nào thuộc product v1.

Phạm vi chốt 2026-11-11 (chủ dự án):

- Nhập sao kê ngân hàng (`BE-P5-E01`) không làm.
- OCR (`BE-P5-E02`) và Ask Freeva (`BE-P5-E05`) chuyển sang [Phase 8](phase-08.md) vì chưa chốt hướng AI.
- Gợi ý danh mục, insight, dự báo chi, what-if tính bằng quy tắc và số liệu từ sổ; không gửi dữ liệu ra ngoài, không gọi model.
- Số và cấu hình mang nghĩa sản phẩm (ngưỡng, giới hạn, danh sách, bật/tắt) không hardcode trong app: nằm ở server, sửa trên web admin. Áp dụng cho cả phần đã làm ở Phase 0–4 (`BE-P5-001` / `MOB-P5-001`).
- Không có nút "Không đúng" (chủ dự án 2026-11-11): insight và dự báo là số tính từ sổ; gợi ý danh mục sai thì user chọn lại, server tính là một lần sửa.
- Màn mới có board thiết kế trước khi code (`DS-P5-001`). Chưa paywall; quyền Premium là việc của Phase 7.

Thứ tự: `BE-P5-E08` → `WA-P5-001` → `MOB-P5-E08` → `BE-P5-001` / `MOB-P5-001` → `DS-P5-001` → `PRD-P5-E01` → `E03` → `E04` → `E06`. What-if (`E07`) bỏ (2026-11-11).

### BE-P5-E08 — Cờ và cấu hình phía server
- Status: done — 2026-11-11
- Module: 18, 26
- Gate: post-v1
- Depends: MOB-P0-003
- DoD:
  - **Cờ:** `category_suggest`, `insights`, `forecast` (dùng cho cả `E06` và `E07`). Cờ của phase sau thêm khi làm phase đó (`bank_connect`, `family`, `ocr`, `ai_chat`). Bật theo môi trường, danh sách user (UUID) hoặc phần trăm; phần trăm chia theo hash ổn định của user id để một người không bật/tắt qua lại.
  - **Cấu hình:** mỗi khóa có kiểu, mặc định, giới hạn min/max và mô tả; giá trị sai kiểu hoặc ngoài giới hạn bị từ chối khi lưu. Danh sách khóa ban đầu là kết quả rà soát ở `BE-P5-001`.
  - **API:** `GET /api/v1/app-config` trả cờ đã tính cho user và cấu hình, kèm `version` để app biết có thay đổi. Backend đọc cùng nguồn khi kiểm tra quy tắc, không giữ bản sao số trong code.
  - Cờ tắt thì API tương ứng trả `403 FEATURE_DISABLED`, không chạy ngầm.
  - Mỗi lần đổi cờ hoặc cấu hình ghi audit (người sửa, giá trị trước và sau). Không chứa dữ liệu tài chính của user.
- Note: xong 2026-11-11: module `app-config`, registry 6 cờ + 34 khóa (mặc định bằng giá trị hiện tại), `GET /api/v1/app-config`, API admin GET/PUT/DELETE có version chống ghi đè, ghi + `AppConfigChange` + `AuditEvent` trong một transaction, `FeatureGuard`/`@RequireFeature`, xóa tài khoản gỡ UUID khỏi cờ. Mỗi môi trường tự quản cờ trong DB của mình (không cột môi trường). Migration additive `app_config`. App và DTO chưa đọc các khóa: việc của `BE-P5-001` / `MOB-P5-001`. [Kiến trúc](../docs/architecture/app-config.md).

### WA-P5-001 — Màn cờ và cấu hình trên web admin
- Status: done — 2026-11-11
- Module: 26
- Gate: post-v1
- Depends: BE-P5-E08, WA-P0-002
- DoD: staff xem và sửa cờ (môi trường, danh sách user, phần trăm) và từng khóa cấu hình, thấy mô tả, mặc định, giới hạn và lần sửa gần nhất. Hiện giá trị cũ và mới, xác nhận trước khi lưu. Lỗi kiểm tra hiện tại ô nhập. Mọi thay đổi có audit. Auth single-staff P0 vẫn phải thay trước production (đã ghi ở `WA-P0-002`).
- Note: xong 2026-11-11: trang `/config` trên web admin (link ở header). Nhập credential staff (chỉ giữ trong trang), danh sách cờ và khóa theo nhóm với mô tả, mặc định, giới hạn, lần sửa gần nhất. Sửa → khung "Hiện tại / Sau khi lưu" → Xác nhận lưu; "Về mặc định" cũng qua xác nhận. Lỗi kiểm tra (trên trang và từ API) hiện dưới ô nhập; xung đột version báo tải lại. Đã thử trên trình duyệt với API và PostgreSQL tạm.

### MOB-P5-E08 — App đọc cờ và cấu hình từ server
- Status: done — 2026-11-11
- Module: 18, 26
- Gate: post-v1
- Depends: BE-P5-E08
- DoD: thay `LocalFeatureFlagService` bằng bản đọc `GET /app-config`. Tải khi đăng nhập và khi mở app, lưu bản gần nhất trên máy; mỗi giờ hoặc khi `version` đổi thì tải lại. Không có bản nào (chưa từng tải được) thì cờ coi là tắt và màn cần cấu hình hiện trạng thái "Không tải được, thử lại" thay vì dùng số đoán. Overlay local chỉ có ở bản dev.
- Note: xong 2026-11-11: feature `server_config` — đọc bản trên máy lúc boot, tải khi mở khóa và khi quay lại app (tối đa mỗi giờ), thay bản lưu khi `version` đổi, xóa khi đăng xuất. `ServerConfigViewModel` là `FeatureFlagService` (bỏ `LocalFeatureFlagService`). `ServerConfigGate` hiện "Chưa tải được cài đặt" + Thử lại khi chưa có bản nào. Overlay `FEATURE_FLAGS_ON` chỉ ở bản dev debug. Màn hiện có chưa đọc khóa: `MOB-P5-001`. [Kiến trúc](../docs/architecture/mobile-app-config.md).

### BE-P5-001 / MOB-P5-001 — Chuyển số và cấu hình đang hardcode lên server
- Status: done — 2026-11-11 (BE + 3 PR MOB)
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
- Note: chốt khi lên plan 2026-11-11: (1) cờ `google_sign_in`, `apple_sign_in`, `profile_edit` giữ "Sắp có" khi tắt, chưa viết code — chỉ có tác dụng khi tính năng thật được làm; (2) user chọn mốc ngân sách nào thì server báo mốc đó (bỏ sàn 80%), mốc mặc định admin chỉnh; (3) phiên bản app đọc bằng `package_info_plus`.
- Note: BE xong 2026-11-11: `AppConfigReader` (cache 30 giây) dùng ở ngân sách, dự báo, định kỳ, thông báo, nhập/xuất CSV, nhãn, hồ sơ, mật khẩu; 24 khóa chỉ đọc `limit.*` (test so với DTO); kiểm tra chéo khi lưu; bỏ sàn 80% thông báo ngân sách; giờ nhắc mặc định 21:00; `Currency.symbol`. Web admin hiện khóa chỉ đọc là "Cố định". [Kiến trúc](../docs/architecture/app-config.md).
- Note: MOB PR 1/3 xong 2026-11-11: `ServerConfigBoundary` (app có phiên chỉ chạy khi có cấu hình, lỗi thì Thử lại), `AppLimits` / `AppLimitsSource`; ngân sách, dự báo, trả góp, định kỳ, thẻ, cho mượn, tài sản ròng, đầu tư, báo cáo, Home, mục tiêu, giờ nhắc đọc từ cấu hình; copy màn Thông báo đổi thành "Khi chạm mốc bạn chọn". [Mobile](../docs/architecture/mobile-app-config.md).
- Note: MOB PR 2/3 xong 2026-11-11: cấu hình công khai trước đăng nhập (`/app-config/public`, backend #135), `AppLimitsStore` cắt vòng DI với auth; mật khẩu/email/PIN, độ dài tên và ghi chú, nhãn, ngày đầu kỳ, onboarding, nhập/xuất CSV, góp ý đọc từ cấu hình; dòng thông báo theo `available`; icon danh mục theo `iconTokens`; phiên bản app từ `package_info_plus`. Màu/icon mục tiêu và nhóm icon danh mục giữ theo board (token thiết kế).
- Note: MOB PR 3/3 xong 2026-11-11: danh mục tiền tệ server (`CurrencyCatalog`, tải cùng cấu hình khi đăng nhập) thay `VND ? 0 : 2`, `₫` và `?? 'VND'`; backend `isDefault` trong `/profile/options` từ `NEW_USER_CURRENCY_CODE`. [Mobile](../docs/architecture/mobile-app-config.md).

### DS-P5-001 — Thiết kế màn Phase 5
- Status: done — 2026-11-11
- Module: 5, 14, 18, 24
- Gate: post-v1
- Depends: —
- DoD: board cho gợi ý danh mục (màn ghi chi, nhập CSV), thẻ insight trên Home (dưới thẻ soát tháng) và màn phân tích, dự báo chi cuối tháng, ngày đạt mục tiêu, cài đặt "Gợi ý tự động" (tắt, xóa dữ liệu đã học). Copy ngắn, không chi tiết kỹ thuật.
- Note: xong 2026-11-11: 9 board trên trang canvas **09 · Phase 5** (nhóm R, S, T, U), [pattern](../docs/brand/patterns/R-suggestions-insights.md). Chủ dự án bỏ what-if và nút "Không đúng"; insight có hình so sánh nhỏ; chi tiết mục tiêu đổi ô "Ngày đạt" thành "Hạn" và thêm dải mốc Hôm nay → Hạn → Dự kiến.

### PRD-P5-E01 / MOB-P5-002 — Tắt gợi ý tự động và xóa dữ liệu đã học
- Status: done — 2026-11-11
- Module: 18, 21
- Gate: post-v1
- Depends: BE-P5-E08
- DoD: các gợi ý của Phase 5 chạy trên server của Freeva, không gửi dữ liệu ra ngoài: mặc định bật, user tắt được trong Cài đặt. Tắt thì API gợi ý và insight không trả kết quả cho user đó. User xóa được mapping merchant → danh mục đã học và insight đã lưu. Xuất dữ liệu có các mục này; xóa tài khoản xóa luôn. Đồng ý dùng AI bên ngoài là việc của `PRD-P8-E02`.
- Note: 2026-11-11 bỏ phụ thuộc `BE-P5-E03` (phụ thuộc vòng tròn); phần đồng ý AI bên ngoài chuyển sang Phase 8.
- Note: xong 2026-11-11: `User.autoSuggestEnabled` + `PUT /profile/auto-suggest`; bảng `CategorySuggestionMapping` (E03 ghi) với `GET`/`DELETE /category-suggestions/mappings`; `AutoSuggestPolicy` (cờ bật và user chưa tắt) cho E03/E04/E06; xuất dữ liệu và xóa tài khoản có bảng mới. Insight không lưu (chốt 2026-11-11), nên "dữ liệu đã học" chỉ là cửa hàng đã nhớ. App: dòng "Gợi ý tự động" ở Cá nhân → Ứng dụng (chỉ khi một trong ba cờ bật), màn U.1 và popup U.2. [Kiến trúc](../docs/architecture/auto-suggest.md).

### BE-P5-E03 / MOB-P5-E03 — Gợi ý danh mục
- Status: done — 2026-11-11
- Module: 18, 5
- Gate: post-v1
- Depends: BE-P1-006, BE-P1-011, BE-P5-E08, PRD-P5-E01
- DoD:
  - Từ merchant hoặc ghi chú đề xuất một danh mục và độ tin cậy, theo thứ tự: mapping user đã chấp nhận, lịch sử giao dịch của chính user, danh sách merchant chung.
  - Danh sách merchant chung (Grab, Shopee, Lazada, WinMart, Circle K, Highlands, The Coffee House…) nằm trong cấu hình, sửa được trên web admin.
  - Độ tin cậy là tỷ lệ khớp trong lịch sử; dưới ngưỡng thì không hiện. Ngưỡng là cấu hình (mặc định 60%).
  - Dùng ở màn ghi chi và màn nhập CSV. User sửa được; chấp nhận thì nhớ mapping. Không tự lưu giao dịch.
  - Server đếm tỷ lệ chấp nhận và tỷ lệ sửa (không phụ thuộc nhà cung cấp analytics). Không có nút "Không đúng": user chọn danh mục khác thì tính là sửa.
  - UI: [R.1–R.3](../docs/brand/patterns/R-suggestions-insights.md).
  - Cờ `category_suggest` tắt hoặc user tắt ở `PRD-P5-E01` thì API không đề xuất.
- Note: PR 1/2 xong 2026-11-11: `POST /category-suggestions/suggest` (đã nhớ → lịch sử ≥ 60% → danh sách cửa hàng chung theo icon), `POST /category-suggestions/feedback` (đếm theo ngày không user id, nhớ cửa hàng theo danh mục user chọn kể cả khi sửa — chốt 2026-11-11), `GET /admin/category-suggestions/stats`; kiểu cấu hình `pair_list` + khóa `categorySuggest.*` sửa trên web admin; app: thẻ gợi ý ở màn ghi chi (R.1). [Kiến trúc](../docs/architecture/category-suggestions.md).
- Note: PR 2/2 xong 2026-11-11: xem trước/nhập CSV gợi ý cho dòng tệp để trống danh mục (truy vấn theo lô), `rowCategoryMap` > `merchantCategoryMap` > gợi ý, nhập lần đầu đếm chấp nhận/sửa (`surface = import`) và nhớ cửa hàng; app: chip "Gợi ý N", danh mục đoán màu xanh, sheet đổi danh mục có công tắc áp dụng cho cùng cửa hàng (R.2, R.3).

### BE-P5-E04 / MOB-P5-E04 — Insight cơ bản
- Status: done — 2026-11-12
- Module: 18
- Gate: post-v1
- Depends: BE-P1-007, BE-P2-E02, BE-P3-E01, BE-P5-E08, PRD-P5-E01
- DoD:
  - Bốn dạng, câu theo mẫu có sẵn, mỗi số lấy từ báo cáo, ngân sách hoặc mục tiêu: xu hướng chi, danh mục tăng hoặc giảm, rủi ro vượt ngân sách, giao dịch lệch khỏi mức thường.
  - "Lệch khỏi mức thường": lớn hơn N lần trung bình M tháng của danh mục đó. Cần ít nhất K tháng dữ liệu mới nêu con số. N, M, K là cấu hình (mặc định 2, 3, 2).
  - Chỉ tính theo tiền tệ của hồ sơ; giao dịch loại tiền khác không đưa vào.
  - Home hiện một insight dưới thẻ soát tháng, kèm CTA xem phân tích. Chưa mở tab Insights.
  - Mỗi insight trả kèm số cho hình nhỏ (giá trị kỳ này và so sánh, hoặc đã dùng / ngân sách) và đích khi chạm.
  - Không đủ dữ liệu thì câu không có số. Không bịa phần trăm.
  - UI: [S.1, S.2](../docs/brand/patterns/R-suggestions-insights.md).
  - Cờ `insights` tắt hoặc user tắt thì ẩn thẻ.
- Note: xong 2026-11-12: `GET /insights` tính mỗi lần gọi, không lưu; thứ tự vượt ngân sách → khoản lệch → danh mục tăng/giảm → xu hướng, so với cùng kỳ tháng trước, danh mục con gộp vào gốc; khóa `insights.*` (ngân sách 80%, chênh 15%, N 2, M 3, K 2). App: thẻ "Đáng chú ý" trên Tổng quan (S.1), màn Phân tích (S.2) chưa có thẻ dự báo (thuộc E06). [Kiến trúc](../docs/architecture/insights.md).

### BE-P5-E06 / MOB-P5-E06 — Dự báo chi cuối tháng và ngày đạt mục tiêu
- Status: done — 2026-11-12
- Module: 18, 14
- Gate: post-v1
- Depends: BE-P1-007, BE-P2-E02, BE-P3-E01, BE-P5-E08
- DoD:
  - Khác `BE-P3-E04` (chỉ chiếu khoản định kỳ): dùng tốc độ chi thực tế của tháng đang chạy để dự báo chi đến cuối tháng, so với ngân sách, kèm mức rủi ro thấp / vừa / cao. Ranh giới các mức là cấu hình.
  - Ngày đạt mục tiêu theo mức góp trung bình M tháng gần nhất (M là cấu hình, mặc định 3). Chưa góp lần nào thì nói chưa đủ dữ liệu.
  - Màn hình ghi rõ đây là dự đoán, không phải số đã xảy ra, và nêu cách tính. Không có quỹ đạo tiết kiệm dài hạn.
  - Dự báo chi trả thêm chuỗi cộng dồn theo ngày, trung bình/ngày, mức nên chi mỗi ngày để không vượt, top 3 danh mục.
  - Chỉ tính theo tiền tệ của hồ sơ. Cờ `forecast`.
  - UI: [S.3, T.1](../docs/brand/patterns/R-suggestions-insights.md).

- Note: xong 2026-11-12: `GET /spending-forecast` (đã chi ÷ ngày đã qua × ngày trong tháng, rủi ro so với ngân sách 90%/100%, mức nên chi mỗi ngày, cộng dồn, top 3 danh mục; chưa đủ 3 ngày thì `insufficient`), `GET /goals/{id}/forecast` (mức góp ròng trung bình 3 tháng đã qua trọn, không tính tháng đang chạy — chốt 2026-11-12). App: thẻ dự báo ở đầu Phân tích (S.2), màn Dự báo chi (S.3), thẻ dự kiến + dải mốc trên chi tiết mục tiêu và ô "Hạn" (T.1). [Kiến trúc](../docs/architecture/spend-forecast.md).
### BE-P5-E07 / MOB-P5-E07 — What-if
- Status: wont — chủ dự án chốt 2026-11-11 chỉ đưa insight và dự báo, không làm màn "Thử bớt chi".

### BE-P5-E01 / MOB-P5-E01 — Import sao kê ngân hàng Excel, PDF
- Status: wont — chủ dự án chốt 2026-11-11 không cần. Nhập CSV từ app khác đã có ở `BE-P3-011`.

### MOB-P5-E02 / BE-P5-E02 — OCR hóa đơn
- Status: wont — chuyển sang `BE-P8-E01` / `MOB-P8-E01` (2026-11-11), chờ chốt hướng AI.

### BE-P5-E05 / MOB-P5-E05 — Ask Freeva
- Status: wont — chuyển sang `BE-P8-E03` / `MOB-P8-E03` (2026-11-11), chờ chốt hướng AI.
