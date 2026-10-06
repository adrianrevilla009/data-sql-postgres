# partitioning

A script that range-partitions an Orders table by month, shows which partitions a query touches, and removes the oldest month by detaching it.

## Goal

Show partition pruning and cheap retention: a short date range reads one partition, and old data goes away with `DETACH` and `DROP` instead of a mass `DELETE`.

## Run it

```bash
./run.sh
```

Expected: the partitions list for a 5-day range shows only `orders_2026_03`, then a `rows left:` count after the oldest partition is dropped, then `OK: partition pruning touched 1 of 3 partitions`.

Not run end to end for this write-up: the expected output is derived from reading `run.sh` and `schema.sql`, not from a captured run.

## What it proves

- `schema.sql` creates `orders` partitioned by range on `created_at` with `orders_2026_01`, `_02` and `_03`, and loads 90k rows across them.
- `EXPLAIN` for `created_at >= '2026-03-05' AND created_at < '2026-03-10'` is parsed for partition names; the `OK:` line requires exactly one.
- `ALTER TABLE orders DETACH PARTITION orders_2026_01; DROP TABLE orders_2026_01` removes a month of data instantly; the remaining row count is printed.

## Trade-offs

- The partition key must be in the primary key (`PRIMARY KEY (id, created_at)`), and there are no global unique constraints on other columns.
- Partitions must be created ahead of time; rows outside the defined ranges are rejected.
- Queries that do not filter on `created_at` scan every partition.

## When not to use it

- Do not partition tables under tens of millions of rows.
- Avoid it when most queries lack a time or tenant filter, because pruning will not help.
