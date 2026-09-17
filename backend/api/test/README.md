# Database regression — BE-P0-004

Chạy từ root repo, cần Docker và dependency pnpm đã cài. Các lệnh dưới chỉ dùng container PostgreSQL 16 tạm, không dùng `.env` database development. Cổng `55434` và tên container phải chưa được sử dụng. Password dưới đây chỉ cho fixture local.

```sh
docker run --detach --rm --name freeva-be-p0-004-test \
  --publish 127.0.0.1:55434:5432 \
  --env POSTGRES_USER=audit_test --env POSTGRES_PASSWORD=audit_test_local \
  --env POSTGRES_DB=audit_empty postgres:16-alpine
docker exec freeva-be-p0-004-test pg_isready -U audit_test
```

Chờ `pg_isready` báo accepting connections trước khi tiếp tục.

## Database trống

```sh
DATABASE_URL=postgresql://audit_test:audit_test_local@127.0.0.1:55434/audit_empty \
  pnpm --filter @freeva/api exec prisma migrate deploy
docker exec -i freeva-be-p0-004-test psql -U audit_test -d audit_empty \
  -v ON_ERROR_STOP=1 < backend/api/test/audit-schema.sql
```

## Nâng cấp có dữ liệu

Tạo migration baseline tạm chỉ chứa hai migration trước audit. `migrate deploy` chỉ áp dụng SQL migration; bản schema copy dùng để cấu hình datasource, không tạo bảng audit sớm.

```sh
docker exec freeva-be-p0-004-test createdb -U audit_test audit_upgrade
audit_baseline_dir=$(mktemp -d /tmp/freeva-audit-baseline.XXXXXX)
cp backend/api/prisma/schema.prisma "$audit_baseline_dir/schema.prisma"
mkdir "$audit_baseline_dir/migrations"
cp backend/api/prisma/migrations/migration_lock.toml "$audit_baseline_dir/migrations/"
cp -R backend/api/prisma/migrations/20260826100000_init \
  backend/api/prisma/migrations/20260831120000_core_data_model "$audit_baseline_dir/migrations/"
DATABASE_URL=postgresql://audit_test:audit_test_local@127.0.0.1:55434/audit_upgrade \
  pnpm --filter @freeva/api exec prisma migrate deploy --schema "$audit_baseline_dir/schema.prisma"
docker exec -i freeva-be-p0-004-test psql -U audit_test -d audit_upgrade \
  -v ON_ERROR_STOP=1 < backend/api/test/audit-upgrade-fixture.sql
DATABASE_URL=postgresql://audit_test:audit_test_local@127.0.0.1:55434/audit_upgrade \
  pnpm --filter @freeva/api exec prisma migrate deploy
docker exec -i freeva-be-p0-004-test psql -U audit_test -d audit_upgrade \
  -v ON_ERROR_STOP=1 < backend/api/test/audit-upgrade-check.sql
docker exec -i freeva-be-p0-004-test psql -U audit_test -d audit_upgrade \
  -v ON_ERROR_STOP=1 < backend/api/test/audit-schema.sql
```

Fixture lưu snapshot toàn bộ hàng User/Currency/FinancialAccount/Transaction để so sánh sau nâng cấp, gồm số nguyên lớn hơn giới hạn integer chính xác của JavaScript. Chạy fixture một lần trên database mới. SQL regression audit rollback fixture của riêng nó.

## Chạy deploy lần hai và dọn container

```sh
DATABASE_URL=postgresql://audit_test:audit_test_local@127.0.0.1:55434/audit_empty \
  pnpm --filter @freeva/api exec prisma migrate deploy
DATABASE_URL=postgresql://audit_test:audit_test_local@127.0.0.1:55434/audit_upgrade \
  pnpm --filter @freeva/api exec prisma migrate deploy
docker stop freeva-be-p0-004-test
```

Hai lần deploy cuối phải báo `No pending migrations to apply`. Container `--rm` được xóa khi stop, cùng database fixture; không có named volume.

## Kết quả 2026-09-17

- PostgreSQL 16.14: fresh deploy và upgrade đều pass; deploy lại không có migration chờ.
- SQL regression pass trên cả hai database: ba actor/outcome hợp lệ; actor thiếu/thừa ID; enum/UUID không hợp lệ; outcome null; mã rỗng, chữ hoa, ký tự cấm/newline, quá dài; PK trùng; timestamp defaults; index và không có FK; audit còn sau khi xóa user actor/target.
- Toàn bộ fixture dữ liệu cũ giữ nguyên sau migration, gồm BigInt và timestamp.
- Prisma validate, generate và Nest build pass; 2 API unit test suites / 7 tests pass.
- Database checks chạy riêng bằng `psql`, chưa nằm trong job unit test CI. Service ghi event và enforcement chống sửa/xóa chưa thuộc task này.
