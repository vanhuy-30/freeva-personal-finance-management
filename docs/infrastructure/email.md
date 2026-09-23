# Email giao dịch — Resend / SMTP

Áp dụng `MOB-P1-001`, `BE-P1-001`. Staging dùng Resend qua SMTP; auth phụ thuộc port `EmailSender`, không phụ thuộc vendor. `MailModule` chọn cấu hình, `SmtpEmailSender` thực hiện transport; outbox vẫn chịu trách nhiệm mã hóa token, retry và expiry.

## Cấu hình Render hiện tại

Đặt trong Environment của API rồi deploy:

| Biến | Giá trị |
|---|---|
| `MAIL_PROVIDER` | `resend` |
| `MAIL_FROM` | `Freeva <onboarding@resend.dev>` |
| `SMTP_PORT` | `2465` |
| `RESEND_API_KEY` | API key có quyền gửi email, lưu dưới dạng secret |
| `AUTH_SECRET_KEY` | Key 64 hex hiện có; giữ ổn định giữa các lần deploy |

Preset cố định host `smtp.resend.com`, username `resend`, dùng API key làm password, TLS với kiểm tra certificate. Không cần `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD`; bỏ `SMTP_SECURE` cũ nếu đang override sai mode.

Domain web `*.onrender.com` độc lập với domain gửi email. Sender `onboarding@resend.dev` chỉ gửi thử đến **email của tài khoản Resend**. Để gửi đến người dùng khác, xác minh domain trên Resend rồi đổi `MAIL_FROM` (ví dụ `Freeva <no-reply@freeva.com>`); không cần sửa code. Xem [giới hạn test sender](https://resend.com/docs/knowledge-base/403-error-resend-dev-domain).

[Render Free](https://render.com/docs/free) chặn outbound port 25/465/587. Dùng port TLS 2465 được [Resend hỗ trợ](https://resend.com/docs/send-with-smtp); lựa chọn khác là 2587 với `SMTP_SECURE=false` và STARTTLS bắt buộc. Cần kiểm chứng kết nối trên instance thật. Free instance ngủ có thể làm outbox chậm đến khi API thức lại.

## Kiểm chứng

Sau build, chạy trong môi trường có cùng env (không in key):

```sh
pnpm --filter @freeva/api build
pnpm --filter @freeva/api mail:verify
```

Lệnh chỉ kiểm tra kết nối/TLS/authentication, không gửi email, không mở DB hay worker. Thành công chưa chứng minh sender hợp lệ hoặc email đến inbox.

Checklist E2E staging với email tài khoản Resend:

- Đăng ký trên mobile → email xác thực tự gửi → nhập mã → trạng thái verified.
- Đăng nhập bằng mật khẩu; request gửi lại mã khi còn chưa verify, mã cũ hết hiệu lực.
- Quên mật khẩu → nhận email → reset → mật khẩu cũ và session cũ bị từ chối → login bằng mật khẩu mới.
- Đối chiếu Resend dashboard và inbox/spam; HTTP 202 chỉ xác nhận request, không bảo đảm delivery.
- Kiểm chứng PIN/biometric, background/recents trên thiết bị thực trước khi đóng `MOB-P1-001`.

Không paste key vào chat, commit `.env`, hoặc log nội dung email/token. Provider nhận địa chỉ người nhận và nội dung mã xác thực/reset để chuyển thư; đánh giá vendor/retention trước production.

## Thay nhà cung cấp

Với provider hỗ trợ SMTP, đổi env: `MAIL_PROVIDER=smtp`, `MAIL_FROM`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`; đặt `SMTP_SECURE=true` cho implicit TLS hoặc `false` cho STARTTLS. Ngoài development/test, TLS luôn bắt buộc. `SMTP_FROM` còn được hỗ trợ cho cấu hình cũ; ưu tiên `MAIL_FROM`. Sau chuyển thành công, gỡ key Resend không dùng nữa.

Với provider chỉ có HTTP API, thêm adapter implement `EmailSender` và chọn adapter ở `MailModule`; không sửa auth use case, template hay outbox repository.

Outbox xóa job sau khi SMTP chấp nhận recipient, không phải khi inbox nhận. Retry dùng cùng delivery ID làm header `Resend-Idempotency-Key`; Resend giữ [idempotency 24 giờ](https://resend.com/docs/dashboard/emails/idempotency-keys). SMTP thông thường vẫn at-least-once, có thể gửi trùng sau crash. Nên xử lý hết outbox đang chờ trước khi đổi provider/sender để tránh payload thay đổi cùng idempotency key hoặc gửi trùng giữa hai vendor.
