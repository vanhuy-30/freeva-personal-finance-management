# Góp ý — DS-P2-003

`POST /api/v1/feedback` (Bearer): `kind` (`bug|idea|praise`), `topic` (`record|reports|wallets|categories|appearance|other`), `message` (trim, 1–2000), `allowReply` (người dùng đồng ý được trả lời qua email), `appVersion`. Trả `204`. Hợp đồng: [OpenAPI](../../packages/api-contracts/openapi.yaml).

- Bảng `Feedback`, thuộc user, xoá cùng tài khoản (`ON DELETE CASCADE`). Chỉ văn bản; ảnh chụp màn hình chưa có.
- Tối đa 5 tin mỗi giờ mỗi user, `429` kèm `Retry-After: 3600`. Đếm trong transaction khoá hàng `User` nên không vượt khi gửi song song.
- Nội dung là riêng tư: không log, lỗi DB không phản chiếu. Không nằm trong `GET /account/export`.
- Email trả lời lấy từ tài khoản phía server khi có người đọc; app không gửi email.
