-- Shared tiny Orders domain: 200k orders over 5k customers.
CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  customer_id int           NOT NULL,
  status      text          NOT NULL,
  total       numeric(10,2) NOT NULL,
  created_at  timestamptz   NOT NULL DEFAULT now()
);
INSERT INTO orders (customer_id, status, total, created_at)
SELECT (random() * 4999)::int, (ARRAY['NEW','PAID','SHIPPED'])[1 + (random() * 2)::int],
       (random() * 500)::numeric(10,2), now() - (random() * 365) * interval '1 day'
FROM generate_series(1, 200000);
ANALYZE orders;
