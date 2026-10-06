# pitr-backup

A script that takes a base backup of a Postgres 16.4 container with WAL archiving, drops the `orders` table, and restores to the moment before the drop.

## Goal

Drill point-in-time recovery end to end: base backup, archived WAL, a disaster, and a restore with `recovery_target_time`.

## Run it

```bash
./run.sh
```

Expected: `== base backup`, a `recovery target (just before disaster):` timestamp, `== disaster: orders table dropped`, `rows after recovery: 1001`, then `OK: table restored to the second before DROP, including post-backup insert`.

Not run end to end for this write-up: the expected output is derived from reading `run.sh`, not from a captured run.

## What it proves

- The source container runs with `archive_mode=on` and an `archive_command` copying WAL segments into a Docker volume.
- After `pg_basebackup`, the script inserts row 1001, records `now()` as the target, then drops the table; the restore unpacks the base backup, adds `recovery.signal`, `restore_command` and `recovery_target_time`, and starts a second container.
- The check is that the restored `orders` has 1001 rows: the 1000 from the backup plus the row that exists only in the archived WAL.

## Trade-offs

- PITR gives near-zero data loss but needs continuous archiving, tested restores and retention management.
- The archive here is a local volume on the same host; real setups use pgBackRest or WAL-G with off-host storage.
- The script relies on short `sleep` calls around WAL switches, so timing on a slow machine may need adjusting.

## When not to use it

- Do not treat it as a production backup: archive and data live on one machine.
- Skip PITR for disposable data or when a managed service already provides it.
