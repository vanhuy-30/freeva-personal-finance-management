# Onboarding ba câu trên app — MOB-P3-012, làm lại ở MOB-P6-004

Sau khi xác nhận email, app hỏi ba câu, câu nào cũng "Để sau" được, rồi tới màn Hoàn tất và vào Tổng quan. Ví, mã PIN và ngân sách tháng làm trong app. Contract: `PATCH /profile/onboarding`, `PUT /profile/declared-income` (`BE-P6-002`, thay `/profile/monthly-income`), xem [mobile-profile.md](mobile-profile.md). Thiết kế: [patterns/A3-onboarding-three-questions.md](../brand/patterns/A3-onboarding-three-questions.md), các board `ObGoals3`, `ObIncome`, `ObSaving`, `ObSavingOther`, `ObDone`, `ObHome`, `BudgetAsk`, `DailyLogAsk`.

## Hành vi

- **1/3 Mục tiêu sử dụng:** sáu thẻ, chọn bao nhiêu cũng được (tối đa `onboarding.maxGoals`, mặc định 6): `track`, `budget`, `save`, `debt`, `assets`, `habits`. "Tiếp tục" gửi `goals` theo thứ tự trên board, không theo thứ tự chạm.
- **2/3 Thu nhập:** chọn một khoảng từ `onboarding.incomeBandsVnd` (mốc 5 / 10 / 20 / 40 triệu → năm khoảng) hoặc "Không muốn chia sẻ". "Tiếp tục" gửi `declaredIncome { minMinor, maxMinor }` (không chờ); "Không muốn chia sẻ" và "Để sau" không gửi gì. Đây là thu nhập khai báo, tách với thu nhập thực tính từ giao dịch.
- **3/3 Mục tiêu tài chính:** chọn loại (`onboarding.goalKinds`, thêm `children`, `business`, `health`), "Số tiền" và "Thời hạn". Chọn "Khác" (`custom`) thì hiện ô "Tên mục tiêu", bắt buộc. Không còn thẻ số cần để dành mỗi tháng. "Tiếp tục" khi chưa đủ thì coi như bỏ qua câu này.
- **Mục tiêu chờ ví:** lúc này user chưa có ví nên app lưu nháp trên máy (`AppPreferences.pendingGoal`, có `clientId` cố định và mã băm SHA-256 của email). Tổng quan tạo mục tiêu mỗi lần tải lại khi đã có ví không phải thẻ tín dụng cùng tiền tệ. Nháp bị bỏ khi tài khoản khác đăng nhập trên máy hoặc server từ chối.
- **Hoàn tất:** hình vẽ bằng `CustomPainter` (`JourneyIllustration`, từ SVG của board). "Khám phá Freeva" gọi `finishSetup` và mở app; không qua PIN. Cờ `onboardingCompleted` bật khi tới màn này.
- **Tổng quan lần đầu:** checklist "Bắt đầu nào": "Thêm ví đầu tiên" có nút "Thêm ví" (mở `WalletEditorPage`, xong thì Tổng quan tải lại); khi đã có ví, "Ghi khoản chi đầu tiên" mới có nút "Ghi ngay". Chưa có ví thì nhãn số dư là "Tổng số dư", không ghi "· 0 ví".
- **Đặt ngân sách tháng** (sheet trên Tổng quan, `FirstRunNudgesViewModel`):
  - **Khi hiện:** lần tải Tổng quan đầu tiên mà tháng này chưa có ngân sách và cờ `budgetAsked` chưa bật. Hiện trước sheet nhắc ghi chi, không cùng lúc.
  - **Số gợi ý:** giữa khoảng thu nhập × (100 − `onboarding.savingsSharePercent`)%; không có thu nhập thì ô trống và không có dòng gợi ý.
  - **"Đặt ngân sách":** `PUT /budgets/current` với mức đã nhập và mốc cảnh báo mặc định. Lỗi thì toast, sheet vẫn mở.
  - Bấm nút nào (hoặc đóng sheet) cũng bật cờ, nên chỉ hỏi một lần.
- **Mời bật nhắc ghi chi:** như cũ: đã chọn `track`, có ít nhất một giao dịch, cờ `dailyLogAsked` chưa bật.
- **Cá nhân → Thu nhập hàng tháng:** dòng hiện khoảng (số cũ [x, x] hiện thành tiền). Sheet là cùng danh sách khoảng; chạm một khoảng là lưu, "Không muốn chia sẻ" xoá (`PUT /profile/declared-income`).
- **Nút back hệ thống:** các màn câu hỏi không có nút quay lại (theo board); back hệ thống đưa về câu trước.

## Layer

- **Domain:**
  - `OnboardingGoal { track, budget, save, debt, assets, habits }`.
  - `OnboardingAnswers { goals, declaredIncome }`.
  - `DeclaredIncome { minMinor, maxMinor, midpointMinor }`, `incomeBandsFrom(bounds)`.
  - `PendingGoal`, `PendingGoalUseCases` (`keep`, `flush`).
  - `ProfileUseCases.saveDeclaredIncome`.
- **ViewModel:** `OnboardingViewModel` (ba câu), `FirstRunNudgesViewModel` (mục tiêu chờ ví, sheet ngân sách, sheet nhắc ghi chi), `ProfileViewModel.saveDeclaredIncome`.
- **Widget dùng chung:** `IncomeBandList`, `incomeBandLabel` (onboarding và Cá nhân).
- **Tiền:** dùng `BigInt` trong toàn bộ luồng.

## Khác biệt có chủ ý so với board

- Màn hẹp với chữ lớn: hai ô "Số tiền" / "Thời hạn" xếp chồng.
- Mốc khoảng thu nhập cấu hình bằng VND; tài khoản có tiền tệ khác vẫn thấy các khoảng theo triệu.

## Test

- `onboarding_view_model_test.dart`: sáu mục tiêu gửi theo thứ tự board; chỉ gửi khoảng thu nhập khi đã chọn; "Khác" cần tên; nháp mục tiêu chờ ví, không gắn vào thẻ, bị bỏ khi đổi tài khoản.
- `daily_log_ask_test.dart`: sheet ngân sách hỏi một lần, trước nhắc ghi chi, số gợi ý từ giữa khoảng, không có thu nhập thì trống; "Đặt ngân sách" lưu đúng; golden sáng/tối cho cả hai sheet.
- `profile_test.dart`: gửi / đọc `declaredIncome`, điểm giữa, khoảng từ mốc.
- `auth_golden_test.dart`: `a1_a3_goals`, `a1_a3_income`, `a1_a3_saving`, `a1_a3_saving_other`, `a1_a3_done` (sáng/tối).
- `auth_gate_test` / `auth_entry_widget_test`: đi hết luồng tới Hoàn tất, back hệ thống, 320 pt ở chữ 1.3×.
- Đối chiếu board với golden: `apps/mobile/tool/design_compare` nhóm `A`.
