-- Shared tiny Orders domain: 200k orders over 5k customers. status 'NEW' is ~1% (skewed on purpose).
CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  customer_id int           NOT NULL,
  status      text          NOT NULL,
  total       numeric(10,2) NOT NULL,
  created_at  timestamptz   NOT NULL
);
INSERT INTO orders (customer_id, status, total, created_at)
SELECT (random() * 4999)::int, CASE WHEN g % 100 = 0 THEN 'NEW' ELSE 'SHIPPED' END,
       (random() * 500)::numeric(10,2),
       timestamptz '2026-01-01' + g * interval '2 minutes'      -- append-only: correlates with disk order
FROM generate_series(1, 200000) g;
ANALYZE orders;
