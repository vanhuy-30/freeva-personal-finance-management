# Web admin (Next.js)

- App Router. Server Components mặc định; client khi cần interact.
- CSS variables từ design-tokens. Không hex trong component.
- Gọi API qua `NEXT_PUBLIC_API_BASE_URL`.
- Staff auth P0: opaque Bearer env + một actor UUID cho lookup nội bộ (`WA-P0-002`); không giả lập bypass production. Identity/session/revoke nhiều staff vẫn phải làm trước production.
- Bảng dữ liệu: không tải full PII lên client log.
