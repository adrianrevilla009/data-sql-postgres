#!/usr/bin/env bash
# Expand and contract: rename orders.total -> orders.amount while an "old app" keeps writing.
set -euo pipefail
cd "$(dirname "$0")"
C="lab-zdm-$$"
trap 'docker rm -f "$C" >/dev/null 2>&1 || true' EXIT
docker run -d --name "$C" -e POSTGRES_PASSWORD=lab postgres:16.4 >/dev/null
until docker exec "$C" psql -U postgres -h 127.0.0.1 -c 'select 1' >/dev/null 2>&1; do sleep 1; done
psql() { docker exec -i "$C" psql -U postgres -v ON_ERROR_STOP=1 -qAt "$@"; }

psql -f - < 00_baseline.sql
echo "== EXPAND: add nullable column + trigger keeps both in sync (old app still writes total)"
psql -f - < 01_expand.sql
psql -c "INSERT INTO orders (customer_id, total) VALUES (1, 10.00)"          # old app write during rollout
echo "== MIGRATE: backfill in batches"
psql -f - < 02_backfill.sql
psql -c "INSERT INTO orders (customer_id, amount) VALUES (2, 20.00)"         # new app write; old column filled by trigger
echo "== CONTRACT: new app is the only writer; drop trigger and old column"
psql -f - < 03_contract.sql
missing=$(psql -c "SELECT count(*) FROM orders WHERE amount IS NULL")
cols=$(psql -c "SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name='orders'")
echo "rows with NULL amount: $missing; columns: $cols"
[ "$missing" = "0" ] && [ "$cols" = "id,customer_id,amount" ] && echo "OK: column renamed with no downtime and no lost writes"
