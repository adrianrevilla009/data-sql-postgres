-- Batched backfill: short row locks instead of one long table-wide UPDATE.
DO $$
DECLARE n int;
BEGIN
  LOOP
    UPDATE orders SET amount = total
     WHERE id IN (SELECT id FROM orders WHERE amount IS NULL LIMIT 10000);
    GET DIAGNOSTICS n = ROW_COUNT;
    EXIT WHEN n = 0;
    COMMIT;
  END LOOP;
END $$;
