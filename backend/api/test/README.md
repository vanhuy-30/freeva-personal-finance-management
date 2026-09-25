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

## Auth — BE-P1-001, BE-P1-002

Unit: `pnpm --filter @freeva/api test`. Integration dùng Nest HTTP thật, Prisma/PostgreSQL thật và SMTP transport mock để kiểm tra failure/retry xác định. Không dùng `.env` DB; script bắt buộc `AUTH_TEST_DATABASE_URL` với database tên `auth_test`. Database này phải disposable: mỗi test xóa fixture auth/user/audit. CI tự tạo PostgreSQL service riêng.

```sh
docker run --detach --rm --name freeva-auth-test \
  --publish 127.0.0.1:55434:5432 \
  --env POSTGRES_USER=auth_test --env POSTGRES_PASSWORD=auth_test_local \
  --env POSTGRES_DB=auth_test postgres:16-alpine
docker exec freeva-auth-test pg_isready -U auth_test
DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55434/auth_test \
  pnpm --filter @freeva/api prisma:migrate:deploy
pnpm --filter @freeva/api prisma:generate
AUTH_TEST_DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55434/auth_test \
  pnpm --filter @freeva/api test:integration
```

Coverage: normalization/duplicate registration, Argon2id, verify single-use/expiry/replacement, reset race/replay/purpose/atomic revoke, session ownership/revoke/expiry, shared atomic rate counters + IP/email windows/Retry-After, DB unavailable, SMTP retry/lease/replacement, secret-safe validation, audit reset success. Unit thêm crypto tamper/dummy hash và Pino HTTP serializer.

### Upgrade regression

Dùng baseline chỉ chứa ba migration trước auth. Chạy từ root, cùng container tạm ở trên:

```sh
auth_baseline_dir=$(mktemp -d /tmp/freeva-auth-baseline.XXXXXX)
cp backend/api/prisma/schema.prisma "$auth_baseline_dir/schema.prisma"
mkdir "$auth_baseline_dir/migrations"
cp backend/api/prisma/migrations/migration_lock.toml "$auth_baseline_dir/migrations/"
cp -R backend/api/prisma/migrations/20260826100000_init \
  backend/api/prisma/migrations/20260831120000_core_data_model \
  backend/api/prisma/migrations/20260916000000_audit_event "$auth_baseline_dir/migrations/"
docker exec freeva-auth-test createdb -U auth_test auth_upgrade
DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55434/auth_upgrade \
  pnpm --filter @freeva/api exec prisma migrate deploy --schema "$auth_baseline_dir/schema.prisma"
docker exec -i freeva-auth-test psql -U auth_test -d auth_upgrade -v ON_ERROR_STOP=1 < backend/api/test/auth-upgrade-fixture.sql
DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55434/auth_upgrade \
  pnpm --filter @freeva/api prisma:migrate:deploy
docker exec -i freeva-auth-test psql -U auth_test -d auth_upgrade -v ON_ERROR_STOP=1 < backend/api/test/auth-upgrade-check.sql
docker stop freeva-auth-test
```

Fixture xác nhận email legacy được trim/lowercase, passwordHash/emailVerifiedAt vẫn null, financial BigInt > JS safe integer và các trường cũ không đổi. Migration dừng trước mutation nếu hai email legacy trùng sau normalization; không tự merge tài khoản. Existing audit-upgrade checker P0 dùng `SELECT *`; dùng auth-upgrade checker ở đây khi schema đã thêm cột auth.

### SMTP smoke local (transport thật)

Sau integration, giữ container PostgreSQL `auth_test`; chạy Mailhog riêng, không gửi ra người nhận bên ngoài:

```sh
docker run --detach --rm --name freeva-auth-mail-test \
  --publish 127.0.0.1:51025:1025 --publish 127.0.0.1:58025:8025 mailhog/mailhog:v1.0.1
pnpm --filter @freeva/api build
AUTH_TEST_DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55434/auth_test \
  node backend/api/test/auth-smtp-smoke.cjs
docker stop freeva-auth-mail-test freeva-auth-test
```

Script tạo account fixture riêng, gửi verify/reset qua SMTP Nodemailer → Mailhog, lấy mã từ inbox local, verify/login/reset và xác nhận phiên cũ bị revoke. Không in email/password/token. Chưa kiểm thử SMTP vendor staging/production.

### Kết quả 2026-09-21

- 8 unit suites / 37 tests và 12 HTTP/PostgreSQL integration tests pass; Nest build, TypeScript noEmit, Prisma validate pass.
- Fresh migrate, upgrade bảo toàn legacy/BigInt, collision fail-safe và migrate deploy lần hai pass.
- SMTP transport thật qua Mailhog: verify/reset/login/revoke pass. Lỗi audit được fault-inject trên DB test để kiểm tra rollback reset/login/revoke.
- OpenAPI Redocly minimal validation pass (localhost server là cảnh báo cho môi trường local).
- Dependency audit production còn 4 high, 2 moderate, 1 low ở dependency hiện hữu; xem threat model. Không ghi nhận advisory cho hai dependency auth mới trong lần audit này.

## Google / Apple OAuth — BE-P1-003

Cùng lệnh unit/integration ở trên; không gọi Google/Apple thật. Unit ký JWT RSA thật với JWKS fixture để kiểm tra signature/issuer/audience/azp/iat/exp/nonce và provider outage. HTTP/PostgreSQL test thay verifier bằng fixture identity; kiểm tra challenge expiry/provider binding/replay, email conflict, account mới, Apple không có email ở lần sau, concurrency, audit rollback và session revoke.

Upgrade: tạo database disposable `oauth_upgrade`, baseline gồm bốn migration trước `20260924000000_oauth` (copy schema + migration_lock và các thư mục cũ vào thư mục tạm như ví dụ auth upgrade). Deploy baseline vào DB đó, chạy `oauth-upgrade-fixture.sql` bằng `psql -v ON_ERROR_STOP=1`, deploy toàn bộ migration hiện tại rồi chạy `oauth-upgrade-check.sql`. Fixture so sánh chính xác User/AuthSession/FinancialAccount, gồm số tiền vượt JS safe integer; không dùng database development.

Kết quả 2026-09-24: unit và integration pass, fresh migration/upgrade bảo toàn dữ liệu pass; OpenAPI valid (cảnh báo có sẵn về localhost và profile summary). Chưa smoke với provider console/SDK/tài khoản thật.

## Financial accounts — BE-P1-004

Suite `financial-accounts.integration-spec.ts` chạy cùng `test:integration` và job CI hiện có, dùng guard/session thật, HTTP Nest và PostgreSQL thật. Bắt buộc `AUTH_TEST_DATABASE_URL` trỏ database disposable tên `auth_test`; không dùng database development. Fixture ví/giao dịch được dọn trước khi xóa fixture user.

Ví dụ chạy riêng với container của task (cổng/tên phải còn trống):

```sh
docker run --detach --rm --name freeva-be-p1-004-test \
  --publish 127.0.0.1:55439:5432 \
  --env POSTGRES_USER=auth_test --env POSTGRES_PASSWORD=auth_test_local \
  --env POSTGRES_DB=auth_test postgres:16-alpine
docker exec freeva-be-p1-004-test pg_isready -U auth_test
# Chờ pg_isready báo accepting connections.
DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55439/auth_test \
  pnpm --filter @freeva/api prisma:migrate:deploy
pnpm --filter @freeva/api prisma:generate
pnpm --filter @freeva/api test --runInBand
AUTH_TEST_DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55439/auth_test \
  pnpm --filter @freeva/api test:integration
pnpm --filter @freeva/api build
pnpm --package=@redocly/cli dlx redocly lint packages/api-contracts/openapi.yaml --extends minimal
docker stop freeva-be-p1-004-test
```

Coverage: bốn loại ví, bigint signed boundary và vượt JS safe integer, tổng giao dịch vượt int64, thu/chi/transfer/soft-delete, owner/session expiry/revoke, validation/envelope/no-store, POST normalized replay và race, optimistic version race, khóa type/currency theo lịch sử, archive/restore giữ giao dịch, credit fields, pagination/order, log không dữ liệu tài chính. Test snapshot chủ động commit thay đổi ví và giao dịch giữa hai query; kết quả phải hoàn toàn thuộc snapshot cũ, request sau thấy snapshot mới.

Kết quả local 2026-09-24: 14 unit suites / 117 tests và 2 HTTP/PostgreSQL suites / 33 tests pass; API build và OpenAPI validation pass. Bốn warning OpenAPI có sẵn về localhost và profile thiếu summary. Fresh migration vào PostgreSQL 16 disposable pass; task không thêm migration. Chưa deploy staging.

## Transactions — BE-P1-005

`transactions.integration-spec.ts` chạy trong job `test:integration` hiện có: HTTP Nest, guard/session thật, Prisma/PostgreSQL thật. Bắt buộc `AUTH_TEST_DATABASE_URL` trỏ DB disposable `auth_test`. Test cài trigger gây lỗi có kiểm soát để kiểm tra rollback leg thứ hai khi create/update/delete; dọn trigger bằng finally và chỉ xóa fixture của suite. Không dùng database development.

```sh
docker run --detach --rm --name freeva-be-p1-005-test \
  --publish 127.0.0.1:55440:5432 \
  --env POSTGRES_USER=auth_test --env POSTGRES_PASSWORD=auth_test_local \
  --env POSTGRES_DB=auth_test postgres:16-alpine
docker exec freeva-be-p1-005-test pg_isready -U auth_test
# Chờ accepting connections trước migrate.
DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55440/auth_test \
  pnpm --filter @freeva/api prisma:migrate:deploy
pnpm --filter @freeva/api prisma:generate
pnpm --filter @freeva/api test --runInBand
AUTH_TEST_DATABASE_URL=postgresql://auth_test:auth_test_local@127.0.0.1:55440/auth_test \
  pnpm --filter @freeva/api test:integration --runInBand
pnpm --filter @freeva/api build
pnpm --package=@redocly/cli dlx redocly lint packages/api-contracts/openapi.yaml --extends minimal
docker stop freeva-be-p1-005-test
```

Coverage mới: signed int64/BigInt, ngày lịch/leap day, source/destination signs, zero/self-transfer, FX exact và fractional rejection, quote bất biến, CRUD/khôi phục toàn bộ cặp, số dư derived khi chuyển ví, category bắt buộc cho chi/ownership nhãn, bearer/IDOR, Idempotency-Key/clientId replay/race, stale version kể cả qua leg đối diện, archived wallet, rollback create/update/delete và FX quote, lọc/phân trang, log không PII. Test race chủ động giữ snapshot ví cũ, commit giao dịch đầu tiên rồi thả writer đổi currency: writer phải retry và từ chối đổi denomination.

Fixture [transfer-balance-cases.json](fixtures/transfer-balance-cases.json) được dùng trực tiếp bởi evaluator domain production, không giữ bản kiểm tra cân bằng riêng trong test. Bổ sung zero/self-transfer/ngày/trạng thái xóa/decimal FX/fractional FX.

Kết quả local 2026-09-25: 15 unit/HTTP suites / **145 tests**, 3 HTTP/PostgreSQL suites / **51 tests** pass; API build, fresh migration và OpenAPI validation pass. OpenAPI còn bốn warning có sẵn (localhost và profile thiếu summary). Không thêm migration; chưa deploy staging.
