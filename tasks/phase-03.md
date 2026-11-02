# Phase 3 — epic

[phase-03.md](../docs/product/phases/phase-03.md). Phase 2 đã đóng 2026-10-30; băm ticket khi làm epic. `Gate: v1`: mục tiêu (`BE-P3-E01`) và các ticket `P3-001`…`P3-011` thêm 2026-11-02 (gộp chức năng chồng chéo, bổ sung chức năng còn thiếu).

### BE-P3-E01 / MOB-P3-E01 — Mục tiêu (module 9)
- Status: doing — BE xong 2026-11-02, MOB còn
- Module: 9
- Gate: v1
- Depends: BE-P1-004, BE-P1-005, MOB-P1-006
- DoD: tên, số đích, số hiện tại, ngày đích, ví liên kết, mức đóng góp tháng, icon và màu bằng token. Có sẵn nhóm quỹ khẩn cấp, mua nhà, mua xe, du lịch, học tập, đám cưới, nghỉ hưu để chọn, user vẫn đặt tên riêng. Đóng góp hoặc rút tạo giao dịch đối ứng, hoặc một dòng audit nếu chỉ sửa số đã có. Công thức có test: đích 120000000, hiện có 40000000, còn 10 tháng → cần 8000000 mỗi tháng. Home hiện `hiện tại / đích` và phần trăm. Không tự chuyển tiền.
- Note: BE-P3-E01 xong 2026-11-02: `/api/v1/goals` (CRUD, presets, `contribute` / `withdraw` / `adjust`), transfer cân hai chân khi chọn ví nguồn, audit `goal.adjust`, công thức 8.000.000 có test, OpenAPI, export/xoá tài khoản. Kiến trúc: [goals.md](../docs/architecture/goals.md). MOB-P3-E01 (Home `hiện tại / đích`, màn mục tiêu) chưa làm.

### BE-P3-E02 / MOB-P3-E02 — Vay và công nợ (module 10)
- Status: todo
- Module: 10
- Gate: post-v1
- Depends: BE-P1-005
- DoD: loại thẻ, vay cá nhân, vay mua nhà, khác (cho mượn / đi mượn người quen bản nhẹ ở `BE-P3-007`). Có gốc, dư nợ, lãi suất, số tiền mỗi kỳ, tần suất, ngày đến hạn, ngày bắt đầu, ngày kết thúc. Màn hình tổng nợ, đã trả, còn lại. Mỗi lần trả là một giao dịch. Bộ test lãi dùng số cố định, không `double`. Không biến app thành sản phẩm cho vay.

### BE-P3-E03 / MOB-P3-E03 — Tiền gửi có kỳ hạn (module 11)
- Status: wont — gộp vào `BE-P4-E01` (2026-11-02)
- Module: 11
- Gate: post-v1
- Depends: BE-P1-004
- DoD: một khoản gửi gắn một ví, lãi có công thức và test, không cộng trùng số dư ví. Spec v1 không yêu cầu module này. Được đóng wont nếu beta không cần, và ghi quyết định vào module 11.

### BE-P3-E04 — Dự báo số dư theo quy tắc
- Status: todo
- Module: 14, 15
- Gate: post-v1
- Depends: BE-P2-E01
- DoD: dự báo số dư từ số hiện tại cộng các định kỳ đã biết. Màn hình nêu giả định và cho sửa input. Khác forecast AI ở `BE-P5-E06`: không gọi model.

## Gộp chức năng chồng chéo (thêm 2026-11-02)

### BE-P3-001 / MOB-P3-001 — Gộp hóa đơn vào giao dịch định kỳ
- Status: todo
- Module: 6, 8, 15
- Gate: v1
- Depends: BE-P2-E01, BE-P2-E03, BE-P2-E05
- DoD: một rule định kỳ có hai chế độ: tự ghi (như hiện tại) hoặc nhắc và chờ xác nhận (hóa đơn cũ). Chế độ nhắc có hạn trả, số cố định hoặc ước tính, nhắc trước N ngày qua hộp thư và push; "Đã trả" tạo hoặc trỏ tới giao dịch thật, quá hạn không tự ghi. Hóa đơn một lần là rule không lặp. Migration chuyển `Bill` sang rule, giữ liên kết giao dịch đã trả; API `/bills` trả 410 sau một bản chuyển tiếp. Mobile còn một màn "Định kỳ & hóa đơn". Lịch (module 15) chỉ là màn xem dữ liệu đó, không có dữ liệu riêng. Test: retry/sync không nhân đôi, xác nhận hai lần không ghi hai giao dịch.

### MOB-P3-002 — Bổ sung thẻ soát tháng trên Tổng quan
- Status: todo
- Module: 14
- Gate: v1
- Depends: BE-P2-E08
- DoD: thẻ `NewMonthReviewCard` đã có (thu, chi tháng trước, chỉ hiện đầu tháng) thêm hai dòng: danh mục chi tăng nhiều nhất so với tháng trước nữa và ngân sách tháng trước có vượt không. Số lấy từ `GET /reports/month-review` và ngân sách, không AI, bỏ dòng khi thiếu dữ liệu. Đây là "insight" của v1.

### BE-P3-003 / MOB-P3-003 — Ngưỡng ngân sách mặc định 80 và 100
- Status: todo
- Module: 7, 17
- Gate: v1
- Depends: BE-P2-E02
- DoD: ngưỡng cảnh báo mặc định đổi từ `70, 80, 90, 100` thành `80, 100`; user vẫn thêm được tới 4 ngưỡng. Ngân sách đã lưu giữ nguyên ngưỡng cũ. Màu trạng thái (healthy / warning / critical / over) không đổi.

### MOB-P3-004 — Ẩn quy đổi khi chỉ dùng một loại tiền
- Status: todo
- Module: 2, 14
- Gate: v1
- Depends: MOB-P2-013
- DoD: mục tỷ giá, tiền tệ hiển thị và dòng số quy đổi chỉ hiện khi user có ví, giao dịch hoặc khoản đầu tư ở từ hai loại tiền trở lên. Dữ liệu tỷ giá đã nhập không bị xóa.

## Chức năng bổ sung (thêm 2026-11-02)

### BE-P3-005 / MOB-P3-005 — Đối soát số dư ví
- Status: todo
- Module: 3, 4
- Gate: v1
- Depends: BE-P1-004, BE-P1-005
- DoD: trên chi tiết ví, user nhập số dư thực tế; app hiện chênh lệch và tạo một giao dịch điều chỉnh (`adjustment`) một leg. Điều chỉnh không tính vào thu/chi kỳ, ngân sách, tỷ lệ tiết kiệm; có trong lịch sử ví, export, sổ cái. Sửa hoặc xóa được như giao dịch thường. Ví thẻ tín dụng đối soát theo dư nợ. Test số dư sau điều chỉnh và báo cáo không đổi.

### BE-P3-006 / MOB-P3-006 — Nhắc ghi chi hằng ngày
- Status: todo
- Module: 17
- Gate: v1
- Depends: BE-P2-E05, BE-P2-015
- DoD: loại thông báo `daily_log`, mặc định tắt, user chọn giờ (theo múi giờ hồ sơ), tôn trọng giờ yên. Không gửi nếu hôm đó đã có giao dịch. Bấm thông báo mở thẳng màn ghi giao dịch. Nối công tắc "Nhắc ghi chi" đã có trên màn Thông báo. Tổng kết tuần/tháng trên cùng màn dùng `month_review` khi `MOB-P3-002` xong.

### BE-P3-007 / MOB-P3-007 — Cho mượn và đi mượn
- Status: todo
- Module: 10
- Gate: v1
- Depends: BE-P1-004, BE-P1-005
- DoD: ghi khoản cho mượn (tiền ra khỏi ví thành khoản phải thu) hoặc đi mượn (tiền vào ví thành khoản phải trả) với tên người, số tiền, ngày, hạn tùy chọn, ghi chú. Trả hoặc thu một phần nhiều lần, tất toán. Không phải thu/chi, không tính ngân sách. Phải thu cộng tài sản, phải trả cộng nợ trên Tổng quan và tài sản ròng. Danh sách "Ai nợ mình / Mình nợ ai" kèm tổng. Nhắc khi tới hạn qua loại `debt`. Không lãi suất (vay có lãi là `BE-P3-E02`).

### BE-P3-008 / MOB-P3-008 — Hoàn tiền gắn khoản chi gốc
- Status: todo
- Module: 4, 7, 14
- Gate: v1
- Depends: BE-P1-005, BE-P2-E02
- DoD: từ một khoản chi, tạo hoàn tiền (một phần hoặc toàn bộ) vào một ví. Hoàn tiền trỏ về khoản chi gốc, cùng danh mục, trừ vào chi của danh mục và ngân sách tại kỳ của khoản chi gốc thay vì tính là thu nhập. Tổng hoàn không vượt khoản gốc. Xóa khoản gốc thì hỏi xử lý hoàn tiền đi kèm. Test bảng số báo cáo và ngân sách.

### BE-P3-009 / MOB-P3-009 — Trả góp thẻ tín dụng
- Status: todo
- Module: 3, 4, 6
- Gate: v1
- Depends: BE-P2-E07, BE-P3-001
- DoD: chốt 2026-11-02 cách ghi một lần. Khoản mua là một khoản chi đủ số tiền vào ngày mua trên ví thẻ, tính vào báo cáo và ngân sách tháng mua; dư nợ thẻ tăng đủ số, khớp sao kê. Đổi khoản chi đó thành kế hoạch trả góp: số kỳ, số mỗi kỳ, kỳ đầu. Kế hoạch chỉ là lịch: "số phải trả kỳ này" của thẻ cộng phần trả góp kỳ đó, lịch hiện các kỳ còn lại. Trả thẻ là chuyển khoản ví → thẻ, không phải chi tiêu mới. Phí chuyển đổi hoặc lãi là khoản chi riêng (danh mục phí), không cộng vào khoản mua. Trả trước hạn hoặc hủy thì đóng lịch, khoản chi gốc không đổi. Test: tổng các kỳ bằng giá mua; báo cáo chỉ đếm khoản mua một lần; dư nợ giảm đúng khi trả từng kỳ.

### BE-P3-010 / MOB-P3-010 — Xuất CSV
- Status: todo
- Module: 20, 21
- Gate: v1
- Depends: BE-P1-010
- DoD: xuất giao dịch (lọc theo khoảng ngày, ví) ra CSV UTF-8 có BOM để Excel đọc đúng tiếng Việt. RFC 4180, chặn công thức (`=` `+` `-` `@` đầu ô). Số tiền dạng số không định dạng theo locale, kèm cột tiền tệ. Không thay export JSON (bản sao lưu).

### BE-P3-011 / MOB-P3-011 — Nhập CSV từ app khác
- Status: todo
- Module: 13
- Gate: v1
- Depends: BE-P1-005, BE-P1-009, BE-P3-010
- DoD: nhập CSV/Excel: xem trước, map cột (ngày, số tiền, loại, danh mục, ví, ghi chú), map danh mục và ví về dữ liệu Freeva. Có preset cho Money Lover, Sổ thu chi MISA và file mẫu Freeva (trùng định dạng `BE-P3-010`). Kết quả từng dòng; trùng với giao dịch đã có thì đánh dấu, không ghi đè im lặng. Hoàn tác cả lô. Sao kê ngân hàng PDF/Excel vẫn là `BE-P5-E01`.

### DS-P3-012 / BE-P3-012 / MOB-P3-012 — Onboarding chỉ hỏi điều dùng được
- Status: todo
- Module: 1, 2, 7, 9
- Gate: v1
- Depends: DS-P2-004, BE-P2-E02, BE-P3-E01
- DoD: chốt 2026-11-02. Sau tạo tài khoản chỉ còn ba câu, đều bỏ qua được, rồi tới bước ví và số dư như cũ:
  1. **Mục tiêu sử dụng** (chọn tối đa 2): Quản lý chi tiêu, Tiết kiệm, Quản lý ngân sách. Chi tiêu → khối "Chi tháng" đầu Tổng quan và gợi ý bật nhắc ghi chi (`BE-P3-006`) sau giao dịch đầu. Tiết kiệm → khối mục tiêu đầu Tổng quan. Ngân sách → khối ngân sách đầu Tổng quan và màn gợi ý ngân sách bên dưới.
  2. **Thu nhập hàng tháng** (không bắt buộc): lưu `monthlyIncomeMinor` trên hồ sơ, sửa hoặc xóa được ở Cá nhân. Dùng để gợi ý ngân sách và hiện phần tiết kiệm so với thu nhập. Không log, có trong export, xóa cùng tài khoản.
  3. **Mục tiêu tiết kiệm** (không bắt buộc): tên hoặc nhóm có sẵn, số đích, ngày đích. Tạo một mục tiêu thật (`BE-P3-E01`) và hiện "cần X mỗi tháng"; có thu nhập thì hiện thêm phần trăm thu nhập.
  Có thu nhập thì hiện một màn gợi ý ngân sách (thu nhập trừ số cần tiết kiệm mỗi tháng; quy tắc khi không có mục tiêu chốt ở thiết kế), "Dùng mức này" tạo ngân sách tháng, "Để sau" không tạo gì. Bỏ câu thói quen và nhịp xem lại; migration xóa `trackingHabit`, `reviewCadence`, `onboardingBudgetMinor`; mục tiêu cũ `emergency` gộp vào Tiết kiệm, `debt` và `understand` bỏ; export cập nhật. Thiết kế vẽ lại trên canvas nhóm A trước khi code.

