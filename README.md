# data-sql-postgres

Eight small PostgreSQL 16.4 labs on the Orders domain: reading query plans, choosing indexes, JSONB, partitioning, schema migration tools, zero-downtime changes, connection pooling and point-in-time recovery. Each one is a single script you can run and read in a few minutes.

## What is inside

| Folder | What it shows | Run |
| --- | --- | --- |
| [`query-tuning-explain`](./query-tuning-explain) | `EXPLAIN ANALYZE` on 200k orders before and after an index on `customer_id` | `./run.sh` |
| [`indexes`](./indexes) | Partial index, composite index column order, BRIN versus B-tree size | `./run.sh` |
| [`jsonb`](./jsonb) | GIN `jsonb_path_ops` index serving a `@>` containment query | `./run.sh` |
| [`partitioning`](./partitioning) | Monthly range partitions, pruning, retention by detach and drop | `./run.sh` |
| [`flyway-liquibase`](./flyway-liquibase) | The same two migrations applied by Flyway (SQL) and Liquibase (YAML) | `./run.sh` |
| [`zero-downtime-migrations`](./zero-downtime-migrations) | Renaming a column with expand, backfill and contract steps | `./run.sh` |
| [`pgbouncer-hikari-pooling`](./pgbouncer-hikari-pooling) | PgBouncer absorbing 100 clients with `max_connections=30`, plus Hikari settings | `./run.sh` |
| [`pitr-backup`](./pitr-backup) | Base backup, WAL archive, an accidental `DROP TABLE` and a timed restore | `./run.sh` |

## Prerequisites

- Docker Engine 24 or newer with the Compose plugin (v2); every lab runs Postgres in a throwaway container.
- Bash. No local Postgres, Java or Flyway/Liquibase install is needed; images are pulled on first run (`postgres:16.4`, `flyway/flyway:10.17.3`, `liquibase/liquibase:4.29.2`, `edoburu/pgbouncer:v1.23.1-p2`).

## How to read it

Start with `query-tuning-explain`, then `indexes`; the rest are independent. Every `run.sh` prints its evidence and ends with an `OK:` line when the expected behaviour was observed. The shared Orders table (`id`, `customer_id`, `status`, `total`, `created_at`) is reused across folders.
