# Quyết định còn mở

Đề xuất — chưa phải cam kết pháp lý/vận hành.

| # | Câu hỏi | Đề xuất hiện tại | Status |
|---|---|---|---|
| 1 | Nền tảng phát hành | iOS + Android (Flutter). Web consumer sau. Admin = Next nội bộ. | Chốt stack; web user chưa |
| 2 | Thị trường / pháp lý | Việt Nam, PDPD. Cần luật sư trước store. | Mở |
| 3 | Offline MVP | Queue + retry, không CRDT | Đề xuất |
| 4 | Backend self vs managed | Local = Compose. **Staging** = Render (API+Postgres) + Vercel (web-admin). **Production** hoster chốt khi chuẩn bị Store; region VN (#5). | Staging chốt 2026-09-18; prod vendor mở |
| 5 | Region dữ liệu | Production primary: **Việt Nam** | Chốt 2026-09-18 |
| 6 | Nguồn FX / giá / bank | FX tay ở MVP; partner Phase 6 | Mở |
| 7 | Free vs Premium | Core miễn phí; thu phí mở rộng Phase 7 | Đề xuất |
| 8 | Quy mô đội / QA / budget | Solo/small; process nhẹ | Mở |
| 9 | Crash tooling | Sentry TBD | Mở |
| 10 | Security contact | email TBD | Mở |
