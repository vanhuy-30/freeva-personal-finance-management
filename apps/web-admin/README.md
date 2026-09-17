# @freeva/web-admin

Next.js App Router, port **3001**. Theme từ `@freeva/design-tokens`.

```bash
# repo root
make up && make api
make admin
```

Mở http://localhost:3001 — health và tra cứu tài khoản staff tối thiểu.

Tra cứu yêu cầu Bearer credential khớp `STAFF_AUTH_TOKEN` của API. Credential được nhập qua form password cho từng lần tra cứu, không lưu trong URL/local storage. Chỉ tìm chính xác theo email hoặc UUID; mọi kết quả thành công/không tìm thấy đều ghi audit.
