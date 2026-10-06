# query-tuning-explain

A script that loads 200k Orders rows into a throwaway Postgres 16.4 and compares `EXPLAIN (ANALYZE)` output before and after an index.

## Goal

Show how to read a plan: a sequential scan on `customer_id = 42` turns into index access once `orders_customer_idx` exists. The point is the plan shape, not the milliseconds.

## Run it

```bash
./run.sh
```

Expected: a `== before index` block with a `Seq Scan on orders` line and an `Execution Time`, a `== after index` block with an `Index Scan` or `Bitmap` line and a shorter time, then `OK: seq scan replaced by index access`.

Not run end to end for this write-up: the output above is what the script is written to print, taken from reading `run.sh` and `schema.sql`, not from a captured run.

## What it proves

- `schema.sql` builds 200k orders over about 5,000 customers, so `customer_id = 42` matches roughly 40 rows.
- `run.sh` prints the scan line and execution time before and after `CREATE INDEX orders_customer_idx ON orders (customer_id)`.
- The `OK:` line is printed only if the first plan contains `Seq Scan` and the second contains `Index Scan` or `Bitmap`.

## Trade-offs

- The index speeds reads on `customer_id` but costs disk and slows every insert and update.
- With 200k rows the timings are small and noisy; compare plan shapes, not absolute numbers.
- Data is random, so row counts and timings differ slightly between runs.

## When not to use it

- Do not index small tables, or filters that return a large share of the rows; the planner will rightly keep the sequential scan.
- This is a demo of reading plans, not a benchmark of production-sized data.
