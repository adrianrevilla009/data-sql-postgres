#!/usr/bin/env bash
# Applies the same two migrations with Flyway and with Liquibase against fresh Postgres instances.
set -euo pipefail
cd "$(dirname "$0")"
for tool in flyway liquibase; do
  echo "== $tool"
  docker compose -p "lab-fl-$tool" --profile "$tool" up --abort-on-container-exit --exit-code-from "$tool" "$tool" 2>&1 | grep -iE "successfully|applied|ran |error" || true
  cols=$(docker compose -p "lab-fl-$tool" exec -T db psql -U postgres -qAt -c \
    "SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name='orders'")
  echo "orders columns: $cols"
  docker compose -p "lab-fl-$tool" --profile "$tool" down -v >/dev/null 2>&1
  [ "$cols" = "id,customer_id,status,total,created_at" ] || { echo "FAIL: unexpected schema from $tool"; exit 1; }
done
echo "OK: Flyway and Liquibase produce the same schema"
