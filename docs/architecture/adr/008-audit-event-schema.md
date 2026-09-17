# ADR 008 — Audit event schema

- **Status:** accepted
- **Date:** 2026-09-17
- **Deciders:** engineering
- **Task:** `BE-P0-004`

## Context

Staff tra cứu PII và các yêu cầu export/xóa tài khoản cần truy vết. Phase 0 chưa có auth/staff hoặc service ghi audit. Task này cung cấp schema PostgreSQL trước khi tích hợp các luồng đó.

## Decision

- `AuditEvent` có UUID `id` do Prisma sinh, actor (`user`, `staff`, `system`), action, target, outcome (`success`, `failure`, `denied`) và hai timestamp `timestamptz`.
- `occurredAt` là thời điểm xảy ra; `createdAt` là thời điểm lưu. Cả hai mặc định `now()`; writer tương lai có thể truyền `occurredAt` khi sự kiện đến chậm.
- Actor user/staff bắt buộc UUID `actorId`; system bắt buộc null. Target gồm mã loại và UUID optional. Actor/target không có FK: staff chưa có bảng, và xóa đối tượng không được tự động cascade mất audit.
- `action` tối đa 100 ký tự; `targetType` tối đa 50. SQL CHECK yêu cầu regex `^[a-z][a-z0-9._]*$`. Đây là mã do ứng dụng định nghĩa, không nhận trực tiếp từ input người dùng. Regex chỉ kiểm tra cú pháp, không bảo đảm nội dung không có PII.
- Không có JSON metadata, message tự do, email, IP, token, số tài khoản hoặc số tiền. UUID có thể liên kết người dùng, vẫn cần bảo vệ và chính sách retention/xóa; không coi là dữ liệu vô danh.
- Index theo actor + thời gian, target + thời gian và thời gian để hỗ trợ tra cứu. Không thêm sync/clientId/version/updatedAt vì đây là lịch sử nội bộ, không phải dữ liệu client đồng bộ.
- CHECK nằm trong migration SQL vì Prisma schema không biểu diễn được các ràng buộc này. Migration sau phải bảo toàn chúng.

## Consequences và phần hoãn

- Đây chỉ là khung schema: chưa writer, API, event thực tế, phân quyền đọc/ghi hay tích hợp auth/admin/export.
- Bảng vẫn có thể UPDATE/DELETE bởi role có quyền; chưa có append-only enforcement, chữ ký, hash chain hoặc bảo vệ khỏi DB administrator. Không tuyên bố audit bất biến.
- Retention, xử lý UUID khi xóa tài khoản và quyền truy cập audit phải chốt trước tích hợp `BE-P1-010` / `WA-P0-002`. Không tự đặt thời hạn lưu giữ hoặc chặn xóa tài khoản bằng FK.
- Event catalog, cơ chế ghi cùng transaction nghiệp vụ và hành vi khi ghi audit thất bại được chốt ở task tích hợp. Chưa giảm rủi ro thiếu event thực tế chỉ bằng việc có bảng.
- Không thay đổi API public, OpenAPI hoặc bảng tài chính hiện có.

Kiểm chứng: [SQL regression và migration upgrade](../../../backend/api/test/README.md).
