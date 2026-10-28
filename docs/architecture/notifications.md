# Thông báo và giờ yên — BE-P2-E05 / MOB-P2-E05

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `/api/v1/notification-preferences`, `/api/v1/notifications`. Module: [17-notifications](../product/modules/17-notifications.md).

## Cách gửi

E05 tạo hàng hộp thư trong app. App gọi `POST /notifications/evaluate` lúc mở/resume; worker API cũng đánh giá mỗi 60 giây (không chạy khi `NODE_ENV=test`). Push lúc app tắt thuộc `BE-P2-015` (FCM).

Cảnh báo bảo mật (phiên đăng nhập khác) vẫn so id phiên trên máy; banner vẫn hiện trong giờ yên, thông báo hệ thống bị chặn khi đang giờ yên.

## Loại

| kind | Nguồn | Mặc định |
|---|---|---|
| `budget` | Ngân sách hiện tại, ngưỡng ≥ 80 | bật |
| `recurring` | Rule active, ngày trước `nextExecutionDate` | bật |
| `security` | Máy (`sessionAlertsEnabled`) | local |
| `goal` `debt` `card` `month_review` `insight` | Chưa có module | khóa, `available=false` |

Bật loại khóa trả 422 `NOTIFICATION_SOURCE_UNAVAILABLE`. Payload chỉ `titleKey` / `bodyKey` / `params` (ngưỡng, `periodFrom`, `executionDate`) — không số dư, số tiền, tên rule.

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
