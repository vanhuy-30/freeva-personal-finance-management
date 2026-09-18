# Privacy và tuân thủ (Việt Nam)

Thị trường đầu: VN. Áp dụng tinh thần PDPD (Nghị định 13/2023 và luật liên quan). Đây không phải tư vấn pháp lý — cần review luật sư trước khi store.

## Data map (bản đầu)

| Loại | Ví dụ | Cơ sở | Retention (đề xuất, chưa chốt) |
|---|---|---|---|
| Tài khoản | email, tên | Hợp đồng / consent | Đến khi xóa TK + 30 ngày |
| Tài chính | GD, số dư | Mục đích dịch vụ | Đến khi xóa TK |
| Thiết bị | device id, IP login | Bảo mật | 90 ngày log |
| Hỗ trợ | nội dung ticket | Consent | 12 tháng |

## Quyền user

Xem, xuất (JSON/CSV máy đọc), sửa, xóa tài khoản, rút consent.

## Bên thứ ba (dự kiến)

Danh sách công khai (bản nháp): [privacy-policy.md](../legal/privacy-policy.md) §10. Không nhân bản bảng vendor ở đây.

Local P0: không có bên thứ ba production (compose self-host). Trước MVP: hosting (region **VN**, vendor TBD), email OTP, store, crash, analytics — nhà cung cấp cụ thể còn mở. Sau MVP không cam kết: push, AI, đối tác ngân hàng (P6, DPA), IAP (P7).

## Copy pháp lý

- [Điều khoản dịch vụ (nháp)](../legal/terms-of-service.md) — `PRD-P0-002`
- [Chính sách bảo mật (nháp)](../legal/privacy-policy.md) — `PRD-P0-002`

Cần luật sư trước store / in-app. Export và xóa tài khoản: `BE-P1-010`.
