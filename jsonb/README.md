# jsonb

A script that loads 150k JSONB order events and compares the plan for a containment query with and without a GIN index.

## Goal

Show a GIN index with `jsonb_path_ops` turning a sequential scan of `payload @> '{"channel":"web","tags":["gift"]}'` into a bitmap scan.

## Run it

```bash
./run.sh
```

Expected: `== no index` shows a `Seq Scan on order_events`, `== GIN jsonb_path_ops` shows a `Bitmap Index Scan` on `events_payload_gin`, then a `matches:` count and `OK: containment query uses the GIN index`.

Not run end to end for this write-up: the expected output is derived from reading `run.sh` and `schema.sql`, not from a captured run.

## What it proves

- `schema.sql` creates `order_events (id, order_id, payload jsonb)` with 150k rows; every 500th event has tags `gift` and `express`, so the query is selective.
- `CREATE INDEX events_payload_gin ... USING gin (payload jsonb_path_ops)` is the only change between the two plans.
- The `OK:` line requires `Seq Scan` before and a `Bitmap` plan after.

## Trade-offs

- `jsonb_path_ops` is smaller and faster than the default `jsonb_ops` but supports containment only, not key-exists (`?`).
- GIN indexes are slower to update than B-trees.
- The query is selective by design; a predicate matching many rows would stay a sequential scan.

## When not to use it

- Do not hide core relational fields such as ids, status or amounts in JSONB; use real columns with constraints.
- Skip GIN when you only ever read one known key; an expression B-tree index is cheaper.
