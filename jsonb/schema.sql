CREATE TABLE order_events (
  id       bigserial PRIMARY KEY,
  order_id int   NOT NULL,
  payload  jsonb NOT NULL
);
INSERT INTO order_events (order_id, payload)
SELECT g, jsonb_build_object(
  'channel', (ARRAY['web','mobile','store'])[1 + (g % 3)],
  'tags', CASE WHEN g % 500 = 0 THEN '["gift","express"]'::jsonb ELSE '["standard"]'::jsonb END,
  'note', md5(g::text))
FROM generate_series(1, 150000) g;
ANALYZE order_events;
