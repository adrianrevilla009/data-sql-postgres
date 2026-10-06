CREATE TABLE orders (
  id          bigserial,
  customer_id int           NOT NULL,
  total       numeric(10,2) NOT NULL,
  created_at  timestamptz   NOT NULL,
  PRIMARY KEY (id, created_at)          -- the partition key must be part of the PK
) PARTITION BY RANGE (created_at);
CREATE TABLE orders_2026_01 PARTITION OF orders FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE orders_2026_02 PARTITION OF orders FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE orders_2026_03 PARTITION OF orders FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
INSERT INTO orders (customer_id, total, created_at)
SELECT (random() * 999)::int, (random() * 500)::numeric(10,2),
       timestamptz '2026-01-01' + random() * interval '89 days'
FROM generate_series(1, 90000);
ANALYZE orders;
