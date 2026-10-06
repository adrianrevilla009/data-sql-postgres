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
plan=$(psql -c "EXPLAIN SELECT count(*) FROM orders WHERE created_at >= '2026-03-05' AND created_at < '2026-03-10'")
echo "== partitions scanned for a 5-day range:"
parts=$(echo "$plan" | grep -o "orders_2026_[0-9]*" | sort -u); echo "$parts"
echo "== retention: detach and drop the oldest partition (no mass DELETE, no vacuum)"
psql -c "ALTER TABLE orders DETACH PARTITION orders_2026_01; DROP TABLE orders_2026_01; SELECT 'rows left: ' || count(*) FROM orders"
[ "$(echo "$parts" | wc -l)" -eq 1 ] && echo "OK: partition pruning touched 1 of 3 partitions"
