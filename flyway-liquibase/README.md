# flyway-liquibase

A Compose file and script that apply the same two Orders migrations with Flyway (SQL files) and Liquibase (YAML changelog), each on a fresh Postgres 16.4.

## Goal

Show the two migration tools producing the same `orders` schema, and how their formats differ.

## Run it

```bash
./run.sh
```

Expected: for each of `== flyway` and `== liquibase`, a few filtered log lines about applied migrations, then `orders columns: id,customer_id,status,total,created_at`, and finally `OK: Flyway and Liquibase produce the same schema`.

Not run end to end for this write-up: the expected output is derived from reading `run.sh`, `compose.yaml` and the migration files, not from a captured run.

## What it proves

- `flyway/V1__create_orders.sql` and `flyway/V2__add_created_at.sql` are plain versioned SQL applied by `flyway/flyway:10.17.3`.
- `liquibase/changelog.yaml` has two change sets (`1-create-orders`, `2-add-created-at`), each with a `rollback` block, applied by `liquibase/liquibase:4.29.2`.
- `run.sh` queries `information_schema.columns` after each tool and fails unless the column list matches exactly; it tears down each stack with `down -v`.

## Trade-offs

- Flyway is SQL-first and simple, but undo migrations are a paid feature.
- Liquibase has database-neutral change types and rollbacks in the changelog, but it is more verbose and you still need to know the SQL it generates.
- The check compares column names and order only, not types or indexes.

## When not to use it

- Skip both for throwaway schemas, or in tests where ORM auto-DDL is acceptable.
- Do not use auto-DDL against production data.
