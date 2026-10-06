# indexes

A script that creates a partial index, a composite index and BRIN and B-tree indexes on the same 200k-row Orders table and checks which plans use them.

## Goal

Show that an index is used only when the query matches how it was built: partial predicate, leading column, and physical ordering for BRIN.

## Run it

```bash
./run.sh
```

Expected: `NEW:` shows a scan on `orders_open_idx` while `SHIPPED:` does not; `leading column used:` shows `orders_cust_created_idx` while `without leading col:` does not; two index sizes are listed; the last line is `OK: partial and composite indexes are used only when the query matches them`.

Not run end to end for this write-up: the expected output is derived from reading `run.sh` and `schema.sql`, not from a captured run.

## What it proves

- `orders_open_idx` is a partial index on `created_at WHERE status = 'NEW'`; `schema.sql` makes `NEW` about 1% of rows, so the planner picks it only for `status = 'NEW'` queries.
- `orders_cust_created_idx (customer_id, created_at)` serves a filter on `customer_id` but not one on `created_at` alone.
- `orders_created_brin` and `orders_created_btree` index the same append-only timestamp; the size query prints both so you can compare them.

## Trade-offs

- Every index slows writes and takes space.
- Partial indexes are small but serve only matching predicates; BRIN works only when values follow disk order, which `schema.sql` arranges on purpose.
- The `OK:` check covers the partial and composite indexes only; BRIN size is printed, not asserted.

## When not to use it

- Do not add indexes speculatively; check `pg_stat_user_indexes` and drop unused ones.
- Avoid BRIN on randomly ordered columns.
