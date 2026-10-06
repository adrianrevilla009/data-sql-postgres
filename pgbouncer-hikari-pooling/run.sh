#!/usr/bin/env bash
# 100 concurrent clients: direct to Postgres (max_connections=30) fails; through PgBouncer it works.
set -euo pipefail
cd "$(dirname "$0")"
P=lab-pool
trap 'docker compose -p $P down -v >/dev/null 2>&1 || true' EXIT
docker compose -p $P up -d --wait db pgbouncer >/dev/null
sleep 3
burst() {  # $1 = host:port target service, runs 100 parallel sessions holding a connection ~2s
  local host=$1 ok=0
  for i in $(seq 1 100); do
    ( docker compose -p $P exec -T db env PGPASSWORD=lab psql -h "$host" -p 5432 -U postgres -qAt \
        -c "SELECT pg_sleep(2)" >/dev/null 2>&1 && echo ok || echo fail ) &
  done | sort | uniq -c
  wait
}
echo "== direct to Postgres (max_connections=30)"; burst db | tee /tmp/direct.$$
echo "== through PgBouncer (transaction mode, pool 5)"; burst pgbouncer | tee /tmp/bounced.$$
echo "server connections used by PgBouncer pool:"
docker compose -p $P exec -T db psql -U postgres -qAt -c "SELECT count(*) FROM pg_stat_activity WHERE backend_type='client backend'"
grep -q fail /tmp/direct.$$ && ! grep -q fail /tmp/bounced.$$ && echo "OK: PgBouncer absorbed 100 clients on 5 server connections"
rm -f /tmp/direct.$$ /tmp/bounced.$$
