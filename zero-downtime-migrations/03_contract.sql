DROP TRIGGER orders_sync_trg ON orders;
DROP FUNCTION orders_sync();
ALTER TABLE orders ALTER COLUMN amount SET NOT NULL;
ALTER TABLE orders DROP COLUMN total;
