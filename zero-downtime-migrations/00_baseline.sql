CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  customer_id int           NOT NULL,
  total       numeric(10,2) NOT NULL
);
INSERT INTO orders (customer_id, total) SELECT g % 100, g FROM generate_series(1, 50000) g;
