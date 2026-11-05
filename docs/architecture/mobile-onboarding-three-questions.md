# Onboarding ba câu trên app — MOB-P3-012

Sau khi xác nhận email, app hỏi ba câu, câu nào cũng "Để sau" được. Có thu nhập thì hiện thêm màn gợi ý ngân sách, sau đó là bước ví và PIN như trước. Contract: [goals.md](goals.md) (`POST /goals/preview`), `PATCH /profile/onboarding`, `PUT /profile/monthly-income`. Thiết kế: [patterns/A3-onboarding-three-questions.md](../brand/patterns/A3-onboarding-three-questions.md), các board `ObGoals3`, `ObIncome`, `ObSaving`, `ObBudgetSuggest`, `DailyLogAsk`.

## Hành vi

- **1/3 Mục tiêu sử dụng:** chọn tối đa hai trong ba: Quản lý chi tiêu (`track`), Tiết kiệm (`save`), Quản lý ngân sách (`budget`). Khi đã chọn đủ hai, thẻ thứ ba không nhận chạm nữa (board vẽ thẻ này bình thường, không làm mờ). "Tiếp tục" gửi `goals`.
- **2/3 Thu nhập:** nhập bằng bàn phím số (board không vẽ bàn phím) hoặc chọn chip 10/15/25/40 triệu (chip chỉ hiện khi tiền tệ là VND). "Tiếp tục" gửi `monthlyIncomeMinor` và chờ lưu xong, để câu 3 tính phần trăm trên đúng số vừa nhập. "Để sau" bỏ số đã gõ.
- **3/3 Mục tiêu tiết kiệm:** chọn nhóm (Khác là `custom`), "Cần có" và "Đến khi" (sheet lịch dùng chung với màn tạo mục tiêu). Thẻ xanh "Mỗi tháng cần để dành X · Y% thu nhập" lấy X và Y từ `POST /goals/preview` (chờ 300 ms sau lần sửa cuối rồi mới gọi); không có thu nhập thì không có phần %. "Tiếp tục" khi chưa nhập đủ ba ô thì coi như bỏ qua câu này.
- **Mục tiêu chờ ví:** API cần ví liên kết, mà lúc trả lời câu 3 user chưa có ví nào. Vì vậy app lưu nháp mục tiêu trên máy (`AppPreferences.pendingGoal`), có `clientId` cố định và mã băm SHA-256 của email để biết nháp thuộc tài khoản nào.
  - **Khi tạo:** sau bước ví, và mỗi lần Tổng quan tải lại. App gắn mục tiêu vào ví đầu tiên không phải thẻ tín dụng, cùng tiền tệ.
  - **Khi bỏ nháp:** khi một tài khoản khác đăng nhập trên máy này, hoặc khi server từ chối nháp (ví dụ ngày đích đã qua).
- **Gợi ý ngân sách:** chỉ hiện khi có thu nhập và còn số để chi. Đây là phép tính trên app:
  - **Có mục tiêu:** nên chi = thu nhập − `requiredPerMonthMinor` (số lấy từ preview).
  - **Không có mục tiêu:** để dành 20%, nên chi = thu nhập × 80%, kèm câu "Chưa có mục tiêu nên tạm để dành 20%."
  - Thanh hai màu chia theo đúng tỉ lệ thật.
  - "Dùng mức này" tạo ngân sách tháng như bước ngân sách cũ; nếu API lỗi hoặc đã có ngân sách thì giữ `budgetDraftMinor` trên máy. "Để sau" không tạo gì.
- **Mời bật nhắc ghi chi** (sheet trên Tổng quan, `FirstRunNudgesViewModel`):
  - **Khi hiện:** đã chọn `track`, có ít nhất một giao dịch và cờ `dailyLogAsked` chưa bật.
  - **Giờ nhắc:** mặc định 21:00, chọn lại bằng popup giờ của màn Thông báo.
  - **"Bật nhắc":** lưu `dailyLogTime` rồi bật `dailyLog`.
  - Bấm nút nào (hoặc đóng sheet) cũng bật cờ, nên chỉ hỏi một lần.
- **Cá nhân:** thêm dòng "Thu nhập hàng tháng" (giá trị hoặc "Chưa đặt"). Sheet sửa có "Lưu" và "Xoá thu nhập", gọi `PUT /profile/monthly-income`.
- **Tổng quan:** bỏ mục tiêu `debt`, nên khối thẻ tín dụng luôn nằm sau "Chi tháng".
- **Nút back hệ thống:** các màn câu hỏi không có nút quay lại (theo board); back hệ thống đưa về câu trước.

## Layer

- **Domain:**
  - `OnboardingGoal { track, save, budget }`.
  - `OnboardingAnswers { goals, monthlyIncomeMinor }`.
  - `PendingGoal`, `PendingGoalUseCases` (`keep`, `flush`).
  - `GoalPreview`, `GoalUseCases.preview`.
  - `ProfileUseCases.saveMonthlyIncome`.
- **Profile:** bỏ `habit`, `cadence`, `budgetMinor`.
- **ViewModel:** `OnboardingViewModel` (ba câu và gợi ý), `FirstRunNudgesViewModel`, `ProfileViewModel.saveMonthlyIncome`.
- **Màu:** thêm token `data.saving` (green 500) cho phần "để dành" trên thanh.
- **Tiền:** dùng `BigInt` trong toàn bộ luồng.

## Khác biệt có chủ ý so với board

- Màn thu nhập có thêm bàn phím số ghim ở dưới; board chỉ vẽ con số.
- Màu thanh "để dành" là `data.saving` (#2F9E76, green 500); board dùng #3FA57E, màu này không có trong palette.
- Màn hẹp với chữ lớn: hai ô "Cần có" / "Đến khi" xếp chồng, chip nhóm rút gọn chữ.

## Test

- `test/features/onboarding/onboarding_view_model_test.dart`: chỉ gửi `goals` / `monthlyIncomeMinor`; số lấy từ preview; gợi ý có và không có mục tiêu; nháp mục tiêu chờ ví, không gắn vào thẻ, bị bỏ khi đổi tài khoản.
- `daily_log_ask_test.dart`: chỉ hỏi một lần, "Bật nhắc" lưu đúng; golden sáng/tối.
- `auth_golden_test.dart`: `a1_a3_*` (bốn màn, có bản tối khi không có mục tiêu).
- `auth_gate_test` / `auth_entry_widget_test`: đi hết luồng, back hệ thống, 320 pt ở chữ 1.3×.
- Đối chiếu board với golden: `apps/mobile/tool/design_compare` nhóm `A`.
