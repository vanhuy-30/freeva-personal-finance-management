# Backup / restore

## Local

```bash
make up
# dump
docker exec freeva-postgres pg_dump -U freeva freeva > /tmp/freeva.dump
# restore
docker exec -i freeva-postgres psql -U freeva freeva < /tmp/freeva.dump
```

Chạy thử dump/restore ít nhất mỗi khi đổi schema lớn. Backup “có file” ≠ đã thử restore.

## Prod (TBD)

PITR, retention, mã hóa at rest, test restore định kỳ — `INF-P1`.
