# Chính sách bảo mật (bản nháp)

> **Bản nháp nội bộ** — task `PRD-P0-002`. Phiên bản: 2026-09-01.
>
> Đây **không** phải tư vấn pháp lý, **không** phải chính sách có hiệu lực với người dùng cuối. Cần luật sư rà trước khi đưa lên store (kể cả nhãn quyền riêng tư của Apple/Google), website, hoặc màn hình in-app.
>
> Áp dụng tinh thần PDPD (Nghị định 13/2023/NĐ-CP và văn bản liên quan). Data map / retention nội bộ: [privacy-compliance.md](../architecture/privacy-compliance.md). Điều khoản dịch vụ (nháp): [terms-of-service.md](terms-of-service.md). Quyết định còn mở: [DECISIONS-OPEN](../project-state/DECISIONS-OPEN.md).

## 1. Bên kiểm soát dữ liệu

Đơn vị vận hành ứng dụng Freeva (**pháp nhân TBD**, địa chỉ và mã số doanh nghiệp chưa chốt).

Liên hệ quyền riêng tư: **TBD**. Báo cáo lỗ hổng: `security@` **TBD** (#10).

Khi có pháp nhân, mục này sẽ ghi tên, địa chỉ, và kênh tiếp nhận yêu cầu chủ thể dữ liệu.

## 2. Dữ liệu chúng tôi xử lý

Khớp schema / data map hiện tại. Một số mục chỉ xuất hiện khi tính năng Phase tương ứng được bật.

### Tài khoản người dùng

Email (đăng nhập), locale (`vi` / `en`), múi giờ (mặc định `Asia/Ho_Chi_Minh`), tiền tệ mặc định, ngày bắt đầu kỳ tài chính. Họ tên / ảnh đại diện khi có hồ sơ Phase 1.

**Chưa có** trên schema Phase 0: `passwordHash` (sẽ có Phase 1, không log), số tài khoản ngân hàng / IBAN.

### Dữ liệu tài chính (do bạn nhập)

Tên và loại ví (`cash`, `bank`, `ewallet`, `credit`), giao dịch (thu / chi / chuyển khoản), danh mục, nhãn, số dư derived, tỷ giá bạn ghi (nếu có). Đây là dữ liệu nhạy cảm theo mục đích dịch vụ — không log số tiền hay email đầy đủ ([pii-log-checklist.md](../architecture/pii-log-checklist.md)).

### Thiết bị và bảo mật

Định danh thiết bị / phiên (Phase 1), địa chỉ IP khi gọi API, nhật ký kỹ thuật (`userId` UUID, `requestId`, method/path/status). Retention log IP đề xuất: ~90 ngày.

### Hỗ trợ

Nội dung phản hồi / ticket khi bạn gửi (consent). Retention đề xuất: 12 tháng.

### Analytics (không PII)

Sự kiện funnel (`onboarding_started`, `transaction_created`, …) — catalog [analytics-events.md](../product/analytics-events.md). Cấm email, số dư, số tài khoản trong property. Nhà cung cấp analytics **TBD**; stub client = `MOB-P0-004`.

### Không thu thập (MVP)

Dữ liệu sinh trắc học trên máy chủ (PIN / biometrics chỉ mở khóa app trên thiết bị). Token ngân hàng (Phase 6). Nội dung AI (Phase 5).

## 3. Mục đích và cơ sở xử lý

| Mục đích | Cơ sở (đề xuất) | Ghi chú |
|---|---|---|
| Cung cấp sổ thu chi, đồng bộ, hiển thị số dư | Hợp đồng / consent khi đăng ký | Cốt lõi dịch vụ |
| Xác thực, chống lạm dụng, bảo mật tài khoản | Lợi ích hợp pháp / nghĩa vụ bảo mật | Rate limit, phiên, log kỹ thuật |
| Gửi email OTP, xác thực, đặt lại mật khẩu | Thực hiện hợp đồng | Nhà cung cấp email TBD |
| Cải thiện sản phẩm (funnel, crash) | Consent hoặc lợi ích hợp pháp (luật sư chốt) | Không PII tài chính trong event |
| Thông báo push | Consent | Phase 2–3, chưa bật |
| Tuân thủ yêu cầu pháp luật | Nghĩa vụ pháp lý | Khi có căn cứ |

**Không bán** dữ liệu cá nhân. Không dùng dữ liệu tài chính để quảng cáo bên thứ ba.

Consent tùy chọn (sau này): thông báo, AI, kết nối ngân hàng. Có thể rút; rút consent không chặn xuất dữ liệu hay xóa tài khoản.

## 4. Quyền của bạn

Theo tinh thần PDPD, bạn có quyền (khi đã có tài khoản và quy trình Phase 1):

- **Xem** và **sửa** hồ sơ / dữ liệu ghi chép trong app.
- **Xuất** dữ liệu dạng máy đọc (JSON/CSV) — sẽ có trước phát hành (`BE-P1-010`). Chưa ship ở Phase 0.
- **Xóa tài khoản** — cùng `BE-P1-010`; paywall không được chặn quyền này.
- **Rút consent** đối với xử lý không bắt buộc (thông báo, analytics mở rộng, AI, bank connect).
- Khiếu nại với cơ quan có thẩm quyền theo pháp luật Việt Nam.

Cách gửi yêu cầu: kênh TBD cho đến khi có email hỗ trợ. Staff admin tra cứu PII phải có audit (khung audit = `BE-P0-004`).

## 5. Thời hạn lưu

Đề xuất — **chưa chốt** luật sư; trùng [privacy-compliance.md](../architecture/privacy-compliance.md):

| Loại | Retention |
|---|---|
| Tài khoản (email, hồ sơ) | Đến khi xóa TK + 30 ngày |
| Tài chính (GD, số dư, ví) | Đến khi xóa TK |
| Thiết bị / IP login | 90 ngày log |
| Hỗ trợ (ticket) | 12 tháng |

Sao lưu hệ thống có thể giữ bản sao thêm một cửa sổ ngắn sau xóa, rồi hết hạn theo runbook backup (`BE-P0-005`).

## 6. Chuyển dữ liệu ra nước ngoài

Region lưu trữ production primary: **Việt Nam** (chốt DECISIONS-OPEN #5, 2026-09-18). Nhà cung cấp hosting cụ thể vẫn TBD.

Chuyển xử lý ra ngoài Việt Nam (nếu subprocessors như email/crash nằm ngoài VN) cần cơ sở pháp lý do luật sư chốt trước store. Local hiện tại: Postgres/Redis trên máy dev — không phải môi trường user thật.

## 7. Bảo mật (mức cao)

- TLS cho kết nối.
- Mật khẩu băm (Argon2id hoặc bcrypt) — Phase 1; không log mật khẩu, token, số tiền.
- Helmet, CORS allowlist, ValidationPipe.
- Khóa app trên thiết bị (PIN / sinh trắc học).
- Secret không commit git.

Chi tiết kiểm soát: [security.md](../architecture/security.md). Mô hình đe dọa: [threat-model.md](../architecture/threat-model.md).

## 8. Trẻ em

Dịch vụ không hướng tới người dưới 16 tuổi. Không cố ý thu thập dữ liệu trẻ em. Nếu phát hiện tài khoản của người dưới 16 tuổi, chúng tôi sẽ xóa khi có quy trình và căn cứ.

## 9. Thay đổi chính sách

Cập nhật bản nháp trong repo không tự có hiệu lực với người dùng. Bản công bố sau này: thông báo thay đổi trọng yếu trong app hoặc email; nhãn store phải khớp data map ([release.md](../process/release.md)).

## 10. Danh sách bên thứ ba (dự kiến)

Nguồn sự thật cho copy công khai. **Không** đặt tên đối tác ngân hàng hay sản phẩm IAP. Cập nhật bảng này khi chốt vendor hoặc thêm bề mặt — đồng thời rà [threat-model.md](../architecture/threat-model.md).

### Hiện tại (Phase 0, local)

Không có bên thứ ba **production**. API + Postgres + Redis + Mailhog chạy local / compose ([environments.md](../infrastructure/environments.md)). Mailhog chỉ fake mail trên máy dev — không gửi email user thật.

### Trước MVP (dự kiến)

| Bên | Mục đích | Dữ liệu | Phase | Trạng thái |
|---|---|---|---|---|
| Nhà cung cấp hosting cloud (TBD) | Chạy API, Postgres, Redis | Tài khoản + dữ liệu tài chính + log kỹ thuật | 1 | **Production** region **VN** (#5); vendor chốt khi Store. **Staging** hiện: Render (API+DB) + Vercel (admin) — [staging.md](../infrastructure/staging.md) |
| Nhà cung cấp email giao dịch (TBD) | OTP, xác thực email, đặt lại mật khẩu | Địa chỉ email, nội dung mail giao dịch | 1 | Nhà cung cấp chưa chọn; local = Mailhog |
| Apple App Store / Google Play | Phân phối app; Sign-In (Should) | Tài khoản store; email/tên nếu dùng Sign-In | 1 | Dự kiến khi phát hành store |
| Crash reporting (Sentry hoặc tương đương) | Stack crash, độ ổn định | Device / phiên bản app; **không** PII tài chính | 1 | Sentry dự kiến; chưa SDK — #9, `INF-P1-001` |
| Analytics (vendor TBD) | Funnel sản phẩm | Event không PII — [analytics-events.md](../product/analytics-events.md) | 1 | Stub `MOB-P0-004`; vendor chưa chọn |

### Sau MVP — không cam kết

| Bên | Mục đích | Dữ liệu | Phase | Trạng thái |
|---|---|---|---|---|
| Nhà cung cấp push (TBD) | Nhắc ghi chi, hóa đơn | Device token, không số dư trong payload | 2–3 | Chưa; cần consent |
| Nhà cung cấp AI (TBD) | Gợi ý / phân loại (module 18) | Nội dung user chọn gửi | 5 | Won't MVP; opt-in |
| Đối tác ngân hàng (không đặt tên) | Đồng bộ sao kê / số dư | Token kết nối, GD từ đối tác | 6 | Chỉ khi có DPA — [RISKS](../project-state/RISKS.md) R6 |
| Cửa hàng (IAP) | Thu phí Premium | Biên lai store, không chặn ghi chi/xuất/xóa | 7 | Chưa có sản phẩm IAP |

Staff / web admin là nội bộ, không phải bên thứ ba. Mọi tra cứu PII của staff phải audit.
