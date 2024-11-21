CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_name text NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded')),
  amount numeric(14,2) NOT NULL CHECK (amount >= 0),
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO analytics.orders (customer_name, status, amount, completed_at, created_at)
SELECT * FROM (VALUES
  ('Northwind Demo', 'completed', 125000.00, '2026-01-15T10:00:00Z'::timestamptz, '2026-01-10T10:00:00Z'::timestamptz),
  ('Contoso Demo', 'completed', 143500.00, '2026-02-20T10:00:00Z'::timestamptz, '2026-02-12T10:00:00Z'::timestamptz),
  ('Fabrikam Demo', 'completed', 138200.00, '2026-03-18T10:00:00Z'::timestamptz, '2026-03-11T10:00:00Z'::timestamptz)
) AS seed(customer_name, status, amount, completed_at, created_at)
WHERE NOT EXISTS (SELECT 1 FROM analytics.orders);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analytics_reader') THEN
    CREATE ROLE analytics_reader NOLOGIN;
  END IF;
END $$;

GRANT USAGE ON SCHEMA analytics TO analytics_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO analytics_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO analytics_reader;

-- Attach a LOGIN role used only by n8n to analytics_reader outside this demo.
-- Also set: ALTER ROLE <login_role> SET statement_timeout = '15s';
-- Do not grant CREATE, TEMP, write privileges, or access to sensitive schemas.

