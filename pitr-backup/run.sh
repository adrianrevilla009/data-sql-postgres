#!/usr/bin/env bash
# PITR drill: base backup + WAL archive, "oops" DROP TABLE, restore to the moment just before it.
set -euo pipefail
cd "$(dirname "$0")"
V=lab-pitr-$$; C=$V-src; R=$V-restore
trap 'docker rm -f "$C" "$R" >/dev/null 2>&1 || true; docker volume rm "$V-arch" "$V-base" "$V-data" >/dev/null 2>&1 || true' EXIT
IMG=postgres:16.4
docker volume create "$V-arch" >/dev/null; docker volume create "$V-base" >/dev/null
docker run --rm -v "$V-arch:/a" "$IMG" chown postgres /a
docker run -d --name "$C" -e POSTGRES_PASSWORD=lab -v "$V-arch:/archive" "$IMG" \
  -c wal_level=replica -c archive_mode=on \
  -c "archive_command=test ! -f /archive/%f && cp %p /archive/%f" >/dev/null
until docker exec "$C" psql -U postgres -h 127.0.0.1 -c 'select 1' >/dev/null 2>&1; do sleep 1; done
sql() { docker exec -i "$C" psql -U postgres -v ON_ERROR_STOP=1 -qAt "$@"; }

sql -c "CREATE TABLE orders (id serial PRIMARY KEY, total numeric); INSERT INTO orders (total) SELECT g FROM generate_series(1,1000) g"
echo "== base backup"
docker exec "$C" bash -c "rm -rf /tmp/base && pg_basebackup -U postgres -h 127.0.0.1 -D /tmp/base -Ft -z -X none"
docker cp "$C:/tmp/base" - | docker run --rm -i -v "$V-base:/b" "$IMG" tar -x -C /b --strip-components=1
sql -c "INSERT INTO orders (total) VALUES (1001); SELECT pg_switch_wal()" >/dev/null
sleep 1
T=$(sql -c "SELECT now()"); echo "recovery target (just before disaster): $T"
sleep 1
sql -c "DROP TABLE orders; SELECT pg_switch_wal()" >/dev/null
sleep 2
echo "== disaster: orders table dropped"
echo "== restore: unpack base, set recovery_target_time, replay archive"
docker run --rm -v "$V-base:/b" -v "$V-arch:/archive:ro" -v "$V-data:/var/lib/postgresql/data" "$IMG" bash -c "
  tar -xzf /b/base.tar.gz -C /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql/data && chmod 700 /var/lib/postgresql/data
  touch /var/lib/postgresql/data/recovery.signal
  printf \"restore_command = 'cp /archive/%%f %%p'\nrecovery_target_time = '$T'\nrecovery_target_action = 'promote'\n\" >> /var/lib/postgresql/data/postgresql.auto.conf"
docker run -d --name "$R" -e POSTGRES_PASSWORD=lab -v "$V-arch:/archive:ro" -v "$V-data:/var/lib/postgresql/data" "$IMG" >/dev/null
for i in $(seq 1 60); do docker exec "$R" psql -U postgres -h 127.0.0.1 -qAt -c "SELECT NOT pg_is_in_recovery()" 2>/dev/null | grep -q t && break; sleep 1; done
n=$(docker exec "$R" psql -U postgres -h 127.0.0.1 -qAt -c "SELECT count(*) FROM orders")
echo "rows after recovery: $n"
[ "$n" = "1001" ] && echo "OK: table restored to the second before DROP, including post-backup insert"
