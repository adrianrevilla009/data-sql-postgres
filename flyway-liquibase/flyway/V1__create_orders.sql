CREATE TABLE orders (
  id          bigserial PRIMARY KEY,
  customer_id int           NOT NULL,
  status      text          NOT NULL DEFAULT 'NEW',
  total       numeric(10,2) NOT NULL
);
