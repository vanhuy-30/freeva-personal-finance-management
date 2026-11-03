# Thông báo và giờ yên — BE-P2-E05 / MOB-P2-E05

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/notification-preferences`, `/api/v1/notifications`. Module: [17-notifications](../product/modules/17-notifications.md).

## Cách gửi

E05 tạo hàng hộp thư trong app. App gọi `POST /notifications/evaluate` lúc mở/resume; worker API cũng đánh giá mỗi 60 giây (không chạy khi `NODE_ENV=test`). Push lúc app tắt do `BE-P2-015` (FCM), xem mục Push FCM.

Cảnh báo bảo mật (phiên đăng nhập khác) vẫn so id phiên trên máy; banner vẫn hiện trong giờ yên, thông báo hệ thống bị chặn khi đang giờ yên.

## Loại

| kind | Nguồn | Mặc định |
|---|---|---|
| `budget` | Ngân sách hiện tại, ngưỡng ≥ 80 | bật |
| `recurring` | Rule active, ngày trước `nextExecutionDate` | bật |
| `card` | Ví `credit` đang dùng (`BE-P2-E07`) | bật |
| `security` | Máy (`sessionAlertsEnabled`) | local |
| `daily_log` | Chưa ghi giao dịch hôm nay (`BE-P3-006`) | tắt |
| `debt` | Khoản cho mượn / đi mượn sắp hạn hoặc quá hạn (`BE-P3-007`) | tắt |
| `goal` `month_review` `insight` | Chưa có module | khóa, `available=false` |

Bật loại khóa trả 422 `NOTIFICATION_SOURCE_UNAVAILABLE`. Payload chỉ `titleKey` / `bodyKey` / `params` (ngưỡng, `periodFrom`, `executionDate`, `days`, `accountId`) — không số dư, số tiền, tên rule hay tên ví.

Cảnh báo thẻ (`card`): sắp đến hạn khi có `paymentDueDay`, dư nợ > 0 và còn 0–3 ngày (timezone hồ sơ); dư nợ cao khi đã dùng ≥ 70% hạn mức; sắp vượt hạn mức khi ≥ 90%. Dedupe theo ngày đến hạn hoặc tháng tài chính + ngưỡng. Không tạo giao dịch trả nợ.

## Giờ yên

`quietHoursEnabled`, `quietStart` / `quietEnd` (`HH:mm`) theo `User.timezone`. Cửa sổ qua đêm (22:00–07:00) hợp lệ; mốc kết thúc không tính. Trong giờ yên worker/evaluate không tạo hàng; hết giờ yên mà điều kiện còn đúng thì tạo một lần (`dedupeKey`).

## API

Bearer session, `Cache-Control: no-store`.

- `GET/PUT /api/v1/notification-preferences`
- `GET /api/v1/notifications`
- `POST /api/v1/notifications/:id/read`, `POST .../read-all`
- `POST /api/v1/notifications/evaluate`

Có trong `GET /account/export` và xóa theo user. Không log nội dung thông báo.

## Mobile

Feature `lib/features/notifications/`. Màn `/me/notifications` (công tắc), chuông `/notifications` (hộp thư). `NotificationResumeListener` cạnh recurring.

## Push FCM — BE-P2-015 / MOB-P2-015

Firebase Cloud Messaging là nhà cung cấp push ([ADR 013](adr/013-fcm-push.md)). iOS đi qua FCM (APNs key do Firebase giữ). Server gọi FCM HTTP v1 bằng service account (`FCM_SERVICE_ACCOUNT_JSON` hoặc `_BASE64`, chỉ trên dashboard host / secret CI). Thiếu khóa thì push tắt và hộp thư vẫn chạy.

**Token.** `PUT /api/v1/push-tokens` `{ token, platform: ios|android }` gắn một token cho phiên hiện tại; `DELETE /api/v1/push-tokens` gỡ. Bảng `PushToken` khóa ngoại cascade tới `AuthSession` và `User`, nên đăng xuất, thu hồi phiên, đổi/đặt lại mật khẩu, phiên hết hạn và xóa tài khoản đều xóa token trong cùng transaction. Cùng một token chuyển sang phiên mới thì phiên cũ mất token. Token không nằm trong `GET /account/export`. FCM trả `UNREGISTERED` / `INVALID_ARGUMENT` thì server xóa token.

**Gửi.** Sau mỗi lần `evaluate` (worker 60 giây hoặc app mở/resume) server quét hàng hộp thư chưa đọc, chưa `pushedAt`, tạo trong 24 giờ qua, rồi nhận hàng bằng cập nhật `pushedAt` (một lần, không trùng giữa worker và evaluate). Lỗi tạm thời thì trả `pushedAt = null` để lần sau gửi lại.

**Giờ yên.** Evaluate không tạo hàng trong giờ yên, và bước gửi bỏ qua hàng khi đang giờ yên mà không nhận. Hết giờ yên, hàng còn chưa đọc thì gửi đúng một lần.

**Payload.** Chữ vi/en dựng ở server theo `User.locale`, cùng câu với hộp thư: chỉ ngưỡng %, ngày, số ngày. `data` chỉ có `notificationId` và `kind`. Không số dư, số tài khoản, email, tên rule/ví hay id phiên. Hàng có trước migration không bao giờ được push.

**Mobile.** `PushRegistrationListener` đăng ký token sau khi mở khóa và khi resume, chỉ nếu đã được cấp quyền. Quyền được xin khi người dùng bật một loại thông báo (không xin lúc mở app). Đăng xuất / `forgetDevice` xóa token FCM trên máy; server cascade lo phía API. Build thiếu `google-services.json` / `GoogleService-Info.plist` thì push tắt, không lỗi.

## Nhắc ghi chi (BE-P3-006)

Loại `daily_log`, mặc định tắt. `PUT /notification-preferences` nhận `dailyLogEnabled` và `dailyLogTime` (`HH:mm`, mặc định `20:00`, theo `User.timezone`); `GET` trả `dailyLogTime`. Khi bật, evaluate tạo một hàng sau giờ nhắc nếu hôm nay (ngày local) chưa có giao dịch thu/chi/chuyển có `occurredOn` = hôm nay và chưa xóa; giao dịch `adjustment` không tính. Dedupe `daily_log|YYYY-MM-DD`. Giờ yên chặn như các loại khác: hết giờ yên mà trong ngày vẫn chưa ghi thì tạo một lần. Params rỗng; push dùng `kind = daily_log` để mobile mở thẳng màn ghi giao dịch.

## Hóa đơn (BE-P3-001)

Loại `recurring` thêm `bill_due` (trong `remindDaysBefore` ngày trước hạn của rule `remind`) và `bill_overdue` (một lần khi quá hạn), dedupe `bill|due|overdue + ruleId + hạn`. Params chỉ có `ruleId`, `dueDate`, `days`; không có số tiền. Xem [bills.md](bills.md).

Loại `debt` (`BE-P3-007`), mặc định tắt, công tắc `debtEnabled`. Với khoản cho mượn / đi mượn còn nợ có `dueDate`: tạo `debt_due` khi còn ≤ 3 ngày (dedupe `debt|due|{id}|{dueDate}`) và `debt_overdue` khi quá hạn (`debt|overdue|…`). Params chỉ có `debtId`, `direction`, `dueDate`, `days`; push không có tên người hay số tiền. Chi tiết: [personal-debts.md](personal-debts.md).
