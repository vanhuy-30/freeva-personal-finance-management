# Backup / restore — BE-P0-005

## Phạm vi và chiến lược

Phase 0 dùng PostgreSQL 16 local. Backup logical bằng `pg_dump --format=custom`, restore bằng `pg_restore` vào **database mới, trống**. Không restore đè database nguồn; không dùng `--clean`. Dump là snapshot nhất quán của một database, không bao gồm role/global config, Redis, file ngoài DB hoặc PITR/WAL.

Dùng client PostgreSQL 16 trong image Compose, tránh lệch major version. Backup trước thay đổi schema lớn; chạy diễn tập dưới đây sau mỗi thay đổi schema lớn. RPO local là thời điểm dump thành công gần nhất; RTO chưa có SLA. Bản dump chỉ được coi là dùng được sau khi đã restore và kiểm tra.

## Diễn tập tái lập với dữ liệu giả

Từ root repo, cần Docker đang chạy, Node/pnpm và dependencies đã cài:

```bash
bash infra/scripts/test-backup-restore.sh
```

Script tạo container PostgreSQL 16 riêng với cổng loopback ngẫu nhiên, deploy toàn bộ Prisma migrations, seed fixture giả (email `.invalid`, BigInt vượt giới hạn số nguyên chính xác JavaScript, transaction, timestamp, audit event). Dump custom rồi restore vào `backup_restored` mới, ghi đè `DATABASE_URL` bằng địa chỉ container tạm nên không dùng database trong `.env` và không chạm volume Compose development.

Điều kiện pass:

- `pg_restore --exit-on-error --single-transaction` thành công.
- Schema dump khớp (gồm FK, CHECK, indexes, enums); bỏ marker ngẫu nhiên `restrict/unrestrict` của pg_dump khi so sánh.
- Mọi hàng ở mọi bảng public khớp, gồm audit và `_prisma_migrations`; không in dữ liệu ra log.
- Kiểm tra fixture tiền/timestamp và regression audit constraints pass trên bản restore.
- `prisma migrate status` xác nhận schema up to date.

Thư mục tạm có quyền riêng tư, được xóa cùng container/anonymous volume khi script kết thúc (kể cả lỗi). Nếu tiến trình bị kill cưỡng bức hoặc Docker mất kết nối, kiểm tra và dọn đúng container diễn tập còn sót; không dùng lệnh prune toàn hệ thống.

## Backup database Compose local

Chỉ dùng cho môi trường development của repo. Dump có thể chứa dữ liệu nhạy cảm; không commit, upload hay dán nội dung vào log/chat. Các lệnh dùng credential local của Compose.

```bash
make up
umask 077
backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/freeva-backup.XXXXXX")
docker exec freeva-postgres pg_dump -U freeva -d freeva \
  --format=custom --no-owner --no-acl > "$backup_dir/freeva.dump.partial" && \
  mv "$backup_dir/freeva.dump.partial" "$backup_dir/freeva.dump"
```

Chỉ tiếp tục khi dump exit 0 và file không rỗng. File `.partial` không phải backup hợp lệ. Giữ cùng backup: thời điểm UTC, commit/migration hiện tại, PostgreSQL version và checksum (`shasum -a 256`). Không lưu connection string/token. Không đổi schema trong lúc dump.

## Restore local để kiểm chứng

Trong cùng shell, dùng tên database mới cho mỗi lần chạy. `createdb` phải thành công; nếu tên đã tồn tại thì dừng và chọn tên khác. Không chạy restore nếu bước tạo database lỗi.

```bash
restore_db="freeva_restore_$(date -u +%Y%m%d%H%M%S)"
docker exec freeva-postgres createdb -U freeva --template=template0 "$restore_db" && \
  docker exec -i freeva-postgres pg_restore -U freeva -d "$restore_db" \
    --exit-on-error --single-transaction --no-owner --no-acl < "$backup_dir/freeva.dump"
```

Nếu restore lỗi: không chuyển API sang bản restore; giữ nguồn nguyên vẹn, kiểm tra version, dung lượng và archive. Chỉ xóa database restore lỗi sau khi xác nhận đúng tên.

Sau restore thành công, kiểm tra migration history, schema/constraints và dữ liệu theo snapshot lúc backup; không so với database nguồn đang có ghi mới. Đối chiếu số lượng giao dịch và tổng minor units theo từng currency bằng SQL integer/numeric (không gộp tiền khác currency). Với dữ liệu thật, không xuất giá trị tài chính/PII vào log. Chạy smoke test ứng dụng trong môi trường cô lập, vô hiệu hóa job/email/tích hợp bên ngoài trước khi cân nhắc chuyển kết nối. Không chạy seed fixture diễn tập trên bản sao dữ liệu thật.

Dọn sau kiểm chứng: xác nhận đúng database restore, dùng `dropdb` cho database đó và xóa thư mục backup đã tạo khi không còn cần. Local không có retention tự động; bản backup thủ công do người tạo quản lý và phải xóa sau diễn tập nếu không còn mục đích giữ.

## Production — chưa triển khai

Trước staging/production cần chốt owner/on-call, RPO/RTO, lịch backup và diễn tập, PITR/WAL, lưu offsite cùng region được phê duyệt, mã hóa và quyền đọc tối thiểu, quản lý khóa, cảnh báo backup lỗi, checksum và kiểm tra restore. Logical dump ở đây không thay thế giải pháp này.

Retention backup và xử lý yêu cầu xóa tài khoản (kể cả ngăn tái xuất hiện dữ liệu đã xóa khi phục hồi) chưa chốt. Không coi mô tả “cửa sổ ngắn” trong privacy draft là thời hạn đã được thực thi. Chốt chính sách cùng privacy trước khi có dữ liệu người dùng thật; retention audit cũng là quyết định riêng. Không hứa SLA hay thời hạn lưu khi chưa phê duyệt.

## Kết quả đã chạy — 2026-09-17

PostgreSQL 16.14, ba Prisma migrations: diễn tập pass trên máy local. Schema và toàn bộ hàng public khớp sau restore, gồm BigInt, timestamp, audit event và migration history; regression audit pass, Prisma báo schema up to date. Container và archive tạm đã được dọn tự động. Đây là kiểm chứng local với dữ liệu giả, chưa chứng minh RPO/RTO production.
