# zero-downtime-migrations

Four SQL files and a script that rename `orders.total` to `orders.amount` using expand, backfill and contract while writes continue.

## Goal

Show how to rename a column without a lock-induced outage, so old and new application versions can both write during the rollout.

## Run it

```bash
./run.sh
```

Expected: headers for EXPAND, MIGRATE and CONTRACT, then `rows with NULL amount: 0; columns: id,customer_id,amount` and `OK: column renamed with no downtime and no lost writes`.

Not run end to end for this write-up: the expected output is derived from reading `run.sh` and the SQL files, not from a captured run. The script also does not run concurrent writers; the "old app" and "new app" writes are single inserts between the steps.

## What it proves

- `00_baseline.sql` creates `orders` with 50,000 rows; `01_expand.sql` adds a nullable `amount` and a `BEFORE INSERT OR UPDATE` trigger that copies whichever of `total` and `amount` is set.
- `02_backfill.sql` fills `amount` in batches of 10,000 with a commit per batch; `03_contract.sql` drops the trigger and `total` and sets `amount NOT NULL`.
- After an old-style insert (`total`) and a new-style insert (`amount`), the script checks that no row has a NULL `amount` and the columns are `id,customer_id,amount`.

## Trade-offs

- Four deploy steps instead of one `RENAME`, plus a trigger and backfill to maintain.
- No long lock, and each step can be rolled back until the contract step.
- The trigger adds write overhead during the transition.

## When not to use it

- When a maintenance window is acceptable.
- On small tables, where `ALTER TABLE ... RENAME COLUMN` takes only a brief lock.
