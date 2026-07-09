-- ============================================================
-- SILVER — canonical model
-- ============================================================

create or replace table financial_ingestion.silver.customers (
  customer_id string,
  source_client string,
  first_name string,
  last_name string,
  email string,
  is_email_valid boolean,
  tier string, 
  signup_source string,
  is_active number(1,0),
  extra_attributes variant,
  is_valid number(1,0),
  anomaly_reason array
);

create or replace table financial_ingestion.silver.products (
  sku string,
  source_client string,
  product_name string,
  category string,
  unit_price number(12,1),
  currency string,
  is_active number(1,0),
  is_valid number(1,0),
  anomaly_reason array
);


create or replace table financial_ingestion.silver.orders (
  order_id string,
  source_client string,
  customer_id string,
  order_date date,
  order_status string,
  order_channel string,
  is_valid number(1,0),
  anomaly_reason array
);

create or replace table financial_ingestion.silver.transactions (
  transaction_id string,
  source_client string,
  order_id string,
  customer_id string,
  payment_method string,
  payment_amount number(12,1),
  transaction_date date,
  extra_attributes variant,
  is_valid number(1,0),
  anomaly_reason array
);

create or replace table financial_ingestion.silver.transaction_item (
  transaction_id string,
  source_client string,
  sku string,
  description string,
  quantity number,
  unit_price number(12,1),
  is_valid number(1,0),
  anomaly_reason array
);

-- client C only — no standalone payments file exists for client A,
-- their payment info stays embedded in the transaction table
create or replace table financial_ingestion.silver.payments (
  payment_id string,
  source_client string,
  order_id string,
  payment_method string,
  amount number(12,1),
  currency string,
  status string,
  is_valid number(1,0),
  anomaly_reason array
);