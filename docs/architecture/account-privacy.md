# Tài khoản — xuất JSON và xóa — BE-P1-010

Contract: [OpenAPI](../../packages/api-contracts/openapi.yaml) `GET /api/v1/account/export` và `DELETE /api/v1/account`. Không CSV, không UI mobile, không analytics.

## API

Bearer session, `Cache-Control: no-store`, owner lấy từ session. Không nhận `userId`. Không log body, email, ghi chú hay số tiền. Không đòi mật khẩu: tài khoản OAuth có thể không có `passwordHash`.

`GET /api/v1/account/export` trả `200` một snapshot. `schemaVersion` là `SchemaMeta.version`. Thiếu hàng `id = 1` trả `503 ACCOUNT_UNAVAILABLE` và không ghi audit. Snapshot gồm hồ sơ (email, locale, timezone, tiền tệ, ngày tài chính, mốc xác thực và danh mục), provider OAuth không kèm subject, ví, nhóm/danh mục, nhãn, quote FX và giao dịch kể cả đã soft-delete. `amountMinor` và số dư là string integer; `rate` là chuỗi thập phân 8 chữ số. Có `id` và `clientId` để nối quan hệ. Không có `passwordHash`, session, token, mail job hay audit.

`DELETE /api/v1/account` trả `204`. Xóa ngay dữ liệu tài chính và hàng `User` trong một transaction. Không cửa sổ 30 ngày: mốc đó trong bản nháp privacy vẫn chưa được luật sư chốt, và ADR 008 cấm tự đặt thời hạn lưu. Xóa không phụ thuộc `SchemaMeta`. Session, token, mail job và OAuth identity đi theo cascade của `User`.

Cả hai luồng khóa hàng `User` bằng `FOR UPDATE`. User không còn thì `401` và không ghi audit success. Audit lỗi thì rollback: export không trả dữ liệu, xóa không xóa user.

## Audit

Cùng schema `BE-P0-004`, không metadata.

| Action | Khi nào |
|---|---|
| `user.data_export` | Sau khi đọc snapshot, trước khi trả |
| `user.account_delete` | Sau khi xóa dữ liệu sở hữu, trước `User.delete` |

`actorType=user`, `targetType=user`, `outcome=success`. Không FK nên UUID còn sau khi user biến mất. Không job xóa audit. Bảng vẫn chưa append-only.

Thứ tự xóa sở hữu: `TransactionTag`, `Transaction`, gỡ `parentId`/`groupId` rồi `Category`, `CategoryGroup`, `Tag`, `FinancialAccount`, `FxQuote`.

## Ngoài phạm vi

CSV, nút trong app, paywall, và retention backup (`BE-P0-005`) không đổi ở task này.
