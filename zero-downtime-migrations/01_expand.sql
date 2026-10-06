-- Additive and backward compatible: old code never notices.
ALTER TABLE orders ADD COLUMN amount numeric(10,2);

CREATE FUNCTION orders_sync() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.amount IS NULL THEN NEW.amount := NEW.total; END IF;     -- old writer
  IF NEW.total  IS NULL THEN NEW.total  := NEW.amount; END IF;    -- new writer
  RETURN NEW;
END $$;
CREATE TRIGGER orders_sync_trg BEFORE INSERT OR UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION orders_sync();
-- Old column must accept rows from new writers that omit it.
ALTER TABLE orders ALTER COLUMN total DROP NOT NULL;
