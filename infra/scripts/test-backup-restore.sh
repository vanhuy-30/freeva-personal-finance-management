#!/usr/bin/env bash
# BE-P0-005: synthetic data only; never connects to the development database.
set -euo pipefail
umask 077
cd "$(dirname "$0")/../.."
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/freeva-restore.XXXXXX")
container_id=''
cleanup() {
  if [[ -n "$container_id" ]]; then docker rm -f -v "$container_id" >/dev/null; fi
  rm -rf "$work_dir"
}
trap cleanup EXIT
container_id=$(docker run --detach --rm \
  --publish 127.0.0.1::5432 \
  --env POSTGRES_USER=restore_test --env POSTGRES_PASSWORD=restore_test_local \
  --env POSTGRES_DB=backup_source postgres:16-alpine)
ready=false
for ((attempt=0; attempt<60; attempt++)); do
  if docker exec "$container_id" pg_isready -U restore_test -d backup_source >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
[[ "$ready" == true ]] || { echo 'PostgreSQL startup timed out' >&2; exit 1; }
port=$(docker port "$container_id" 5432/tcp)
port=${port##*:}
export DATABASE_URL="postgresql://restore_test:restore_test_local@127.0.0.1:${port}/backup_source"
pnpm --filter @freeva/api exec prisma migrate deploy
docker exec -i "$container_id" psql -X -U restore_test -d backup_source -v ON_ERROR_STOP=1 \
  < backend/api/test/audit-upgrade-fixture.sql >/dev/null
docker exec -i "$container_id" psql -X -U restore_test -d backup_source -v ON_ERROR_STOP=1 <<'SQL' >/dev/null
INSERT INTO "AuditEvent" ("id", "actorType", "action", "targetType", "outcome")
VALUES ('00000000-0000-4000-8000-000000000201', 'system', 'backup.verify', 'database', 'success');
SQL
docker exec "$container_id" pg_dump -U restore_test -d backup_source \
  --format=custom --no-owner --no-acl > "$work_dir/backup.dump"
test -s "$work_dir/backup.dump"
docker exec "$container_id" createdb -U restore_test --template=template0 backup_restored
docker exec -i "$container_id" pg_restore -U restore_test -d backup_restored \
  --exit-on-error --single-transaction --no-owner --no-acl < "$work_dir/backup.dump"

# Compare every public table, including Prisma migration history. PostgreSQL
# serializes BigInt/Decimal directly, without JavaScript number conversion.
for db in backup_source backup_restored; do
  docker exec "$container_id" pg_dump -U restore_test -d "$db" \
    --schema-only --no-owner --no-acl > "$work_dir/$db.schema"
  docker exec -i "$container_id" psql -X -qAt -U restore_test -d "$db" -v ON_ERROR_STOP=1 \
    > "$work_dir/$db.rows" <<'SQL'
SELECT format('SELECT %L || '':'' || row_to_json(t)::text FROM %I.%I t ORDER BY row_to_json(t)::text;',
  tablename, schemaname, tablename)
FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
\gexec
SQL
done
# Newer pg_dump patch releases randomize these psql safety markers.
for db in backup_source backup_restored; do
  sed '/^\\restrict /d; /^\\unrestrict /d' "$work_dir/$db.schema" > "$work_dir/$db.normalized"
done
cmp -s "$work_dir/backup_source.normalized" "$work_dir/backup_restored.normalized"
cmp -s "$work_dir/backup_source.rows" "$work_dir/backup_restored.rows"
docker exec -i "$container_id" psql -X -U restore_test -d backup_restored -v ON_ERROR_STOP=1 \
  < backend/api/test/audit-upgrade-check.sql >/dev/null
docker exec -i "$container_id" psql -X -U restore_test -d backup_restored -v ON_ERROR_STOP=1 \
  < backend/api/test/audit-schema.sql >/dev/null
DATABASE_URL="${DATABASE_URL%/*}/backup_restored" pnpm --filter @freeva/api exec prisma migrate status
docker exec "$container_id" psql -X -At -U restore_test -d backup_restored -c 'SHOW server_version;'
echo 'PASS: dump/restore, schema, all rows, migration history and audit constraints.'
