#!/usr/bin/env bash
# Starts a throwaway Postgres 16.4, runs the lab, removes the container.
set -euo pipefail
cd "$(dirname "$0")"
C="lab-$(basename "$PWD")-$$"
trap 'docker rm -f "$C" >/dev/null 2>&1 || true' EXIT
docker run -d --name "$C" -e POSTGRES_PASSWORD=lab postgres:16.4 >/dev/null
until docker exec "$C" psql -U postgres -h 127.0.0.1 -c 'select 1' >/dev/null 2>&1; do sleep 1; done
psql() { docker exec -i "$C" psql -U postgres -v ON_ERROR_STOP=1 -qAt "$@"; }

psql < schema.sql
plan() { psql -c "EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM orders WHERE customer_id = 42"; }
echo "== before index"; before=$(plan); echo "$before" | grep -E "Scan|Execution"
psql -c "CREATE INDEX orders_customer_idx ON orders (customer_id); ANALYZE orders;"
echo "== after index"; after=$(plan); echo "$after" | grep -E "Scan|Execution"
echo "$before" | grep -q "Seq Scan" && echo "$after" | grep -qE "Index Scan|Bitmap" && echo "OK: seq scan replaced by index access"
