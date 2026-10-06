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
w="payload @> '{\"channel\":\"web\",\"tags\":[\"gift\"]}'"
plan() { psql -c "EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT count(*) FROM order_events WHERE $w" | grep -E "Scan|Execution"; }
echo "== no index"; b=$(plan); echo "$b"
psql -c "CREATE INDEX events_payload_gin ON order_events USING gin (payload jsonb_path_ops); ANALYZE order_events;"
echo "== GIN jsonb_path_ops"; a=$(plan); echo "$a"
echo "matches: $(psql -c "SELECT count(*) FROM order_events WHERE $w")"
echo "$b" | grep -q "Seq Scan" && echo "$a" | grep -q "Bitmap" && echo "OK: containment query uses the GIN index"
