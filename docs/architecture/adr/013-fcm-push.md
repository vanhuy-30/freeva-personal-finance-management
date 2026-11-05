# ADR 013 — Push qua Firebase Cloud Messaging

Trạng thái: chấp nhận (2026-10-30). Task: `BE-P2-015` / `MOB-P2-015`.

## Bối cảnh
E05 chỉ tạo hộp thư trong app. Cần push lúc app tắt cho iOS và Android, không số dư trong payload, tôn trọng giờ yên, token xóa khi đăng xuất / xóa tài khoản.

## Quyết định
- FCM là nhà cung cấp duy nhất; iOS đi qua FCM (APNs key do Firebase giữ).
- Backend gọi FCM HTTP v1 bằng `fetch` và `jose` (đã có), không thêm `firebase-admin`. Port `PushSender` giữ nhà cung cấp tách khỏi domain.
- Token gắn phiên đăng nhập (FK cascade tới `AuthSession`/`User`) để mọi đường kết thúc phiên đều xóa token mà không cần hook.
- Chữ push dựng ở server theo `User.locale` để hiển thị được khi app tắt, không cần code nền Dart.
- Tắt an toàn khi thiếu khóa: backend không cấu hình thì bỏ qua, mobile thiếu file Firebase thì không đăng ký.

## Hệ quả
- Thêm nhà xử lý dữ liệu (Google) cho device token: privacy policy và `DECISIONS-OPEN` #11 cập nhật; luật sư chốt câu chữ consent.
- Gửi tối đa một lần mỗi hàng hộp thư (`pushedAt`); lỗi tạm thời được thử lại trong 24 giờ.
- Chưa kiểm chứng gửi thật trên máy thật cho tới khi owner có project Firebase và APNs key.
