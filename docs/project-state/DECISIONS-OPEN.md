# Quyết định còn mở

Đề xuất — chưa phải cam kết pháp lý/vận hành.

| # | Câu hỏi | Đề xuất hiện tại | Status |
|---|---|---|---|
| 1 | Nền tảng phát hành | iOS + Android (Flutter). Web consumer sau. Admin = Next nội bộ. | Chốt stack; web user chưa |
| 2 | Thị trường / pháp lý | Việt Nam, PDPD. Cần luật sư trước store. | Mở |
| 3 | Offline MVP | Queue giao dịch `POST /api/v1/sync`, optimistic version, không ghi đè, không CRDT (`BE-P1-009`) | Chốt 2026-10-09 |
| 4 | Backend self vs managed | Local = Compose. **Staging** = Render (API+Postgres) + Vercel (web-admin). **Production** hoster chốt khi chuẩn bị Store; region VN (#5). | Staging chốt 2026-09-18; prod vendor mở |
| 5 | Region dữ liệu | Production primary: **Việt Nam** | Chốt 2026-09-18 |
| 6 | Nguồn FX / giá / bank | FX tay ở MVP; partner Phase 6 | Mở |
| 7 | Free vs Premium | Core miễn phí; thu phí mở rộng Phase 7 | Đề xuất |
| 8 | Quy mô đội / QA / budget | Solo/small; process nhẹ | Mở |
| 9 | Crash tooling | **Sentry** cho staging (`INF-P1-001`, ADR 011). SDK tắt khi không có DSN. DSN đặt trên Render/Vercel và `--dart-define` mobile; không commit. Event live chờ project Sentry. | Chốt vendor staging 2026-10-12; DSN vận hành còn mở |
| 10 | Security contact | email TBD | Mở |
| 11 | Push provider | **Firebase Cloud Messaging** (`BE-P2-015`, ADR 013). Push tắt khi thiếu `FCM_SERVICE_ACCOUNT_*`. Cần owner tạo project Firebase, tải `google-services.json` / `GoogleService-Info.plist` (gitignore), upload APNs key, đặt service account trên host. | Chốt vendor 2026-10-30; project Firebase còn mở |
