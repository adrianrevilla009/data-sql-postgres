ALTER TABLE orders ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
CREATE INDEX orders_customer_idx ON orders (customer_id);
