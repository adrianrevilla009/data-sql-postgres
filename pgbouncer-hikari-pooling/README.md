# pgbouncer-hikari-pooling

A Compose file with Postgres (`max_connections=30`) and PgBouncer, a script that fires 100 clients at each, and an `application.properties` with matching Hikari settings.

## Goal

Show PgBouncer in transaction mode serving 100 concurrent clients with a pool of 5 server connections, where direct connections would run out.

## Run it

```bash
./run.sh
```

Expected: under `== direct to Postgres` a count of `ok` and `fail` results with some failures; under `== through PgBouncer` only `ok`; a `client backend` count; then `OK: PgBouncer absorbed 100 clients on 5 server connections`.

Not run end to end for this write-up: the expected output is derived from reading `run.sh` and `compose.yaml`, not from a captured run. The `application.properties` file is configuration only and no script exercises it.

## What it proves

- `compose.yaml` pins `postgres:16.4` with `max_connections=30` and `edoburu/pgbouncer:v1.23.1-p2` with `POOL_MODE=transaction`, `DEFAULT_POOL_SIZE=5`, `MAX_CLIENT_CONN=200`.
- Each burst opens 100 `psql` sessions running `pg_sleep(2)`; the direct burst should exceed 30 connections and fail some, the PgBouncer burst should not.
- `application.properties` sets Hikari `maximum-pool-size=10` and `prepareThreshold=0` for the PgBouncer port 16432.

## Trade-offs

- Transaction pooling breaks session state: session-level `SET`, advisory locks and `LISTEN`.
- Server-side prepared statements are risky on older PgBouncer, hence `prepareThreshold=0`.
- It adds a network hop and another component to run.

## When not to use it

- When the application already holds few connections.
- When it needs session features, or a managed pooler such as RDS Proxy is already in place.
