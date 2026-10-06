#!/usr/bin/env bash
# Starts a throwaway Postgres 16.4, runs the lab, removes the container.
set -euo pipefail
cd "$(dirname "$0")"
C="lab-$(basename "$PWD")-$$"
trap 'docker rm -f "$C" >/dev/null 2>&1 || true' EXIT
docker run -d --name "$C" -e POSTGRES_PASSWORD=lab postgres:16.4 >/dev/null
until docker exec "$C" psql -U postgres -h 127.0.0.1 -c 'select 1' >/dev/null 2>&1; do sleep 1; done
psql() { docker exec -i "$C" psql -U postgres -v ON_ERROR_STOP=1 -qAt "$@"; }
used() { psql -c "EXPLAIN SELECT * FROM orders WHERE $1" | grep -E "Scan" | head -1 | sed 's/^ *//'; }

psql < schema.sql
echo "-- partial index: only open orders"
psql -c "CREATE INDEX orders_open_idx ON orders (created_at) WHERE status = 'NEW'; ANALYZE orders;"
p1=$(used "status = 'NEW' AND created_at > '2026-06-01'"); echo "NEW:     $p1"
p2=$(used "status = 'SHIPPED' AND created_at > '2026-06-01'"); echo "SHIPPED: $p2"
echo "-- composite index: column order matters"
psql -c "CREATE INDEX orders_cust_created_idx ON orders (customer_id, created_at); ANALYZE orders;"
c1=$(used "customer_id = 7 AND created_at > '2026-03-01'"); echo "leading column used:  $c1"
c2=$(used "created_at > '2026-08-01' AND total > 499"); echo "without leading col:  $c2"
echo "-- BRIN vs btree size on an append-only time column"
psql -c "CREATE INDEX orders_created_brin ON orders USING brin (created_at); CREATE INDEX orders_created_btree ON orders (created_at);"
psql -c "SELECT indexrelname || ' ' || pg_size_pretty(pg_relation_size(indexrelid)) FROM pg_stat_user_indexes WHERE indexrelname LIKE 'orders_created_%' ORDER BY 1"
echo "$p1" | grep -q orders_open_idx && ! echo "$p2" | grep -q orders_open_idx \
  && echo "$c1" | grep -q orders_cust_created_idx && ! echo "$c2" | grep -q orders_cust_created_idx \
  && echo "OK: partial and composite indexes are used only when the query matches them"
