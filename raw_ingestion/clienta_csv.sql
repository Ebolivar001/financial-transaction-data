-- ============================================================
-- CLIENT A — CSV reference tables (customers, orders, products)
-- ============================================================

create or replace file format financial_ingestion.bronze.csv_format
  type = csv
  skip_header = 2
  field_optionally_enclosed_by = '"'
  trim_space = true
  skip_blank_lines = true
  error_on_column_count_mismatch = false
  null_if = ('');

create or replace table financial_ingestion.bronze.clienta_customers (
  customer_id string, first_name string, last_name string,
  email string, loyalty_tier string, signup_source string, is_active string
);

copy into financial_ingestion.bronze.clienta_customers
from @financial_ingestion.bronze.raw_files/Customer.csv
file_format = (format_name = financial_ingestion.bronze.csv_format);

create or replace table financial_ingestion.bronze.clienta_orders (
  order_id string, customer_id string, order_date string, order_status string, channel string
);

copy into financial_ingestion.bronze.clienta_orders
from @financial_ingestion.bronze.raw_files/Orders.csv
file_format = (format_name = financial_ingestion.bronze.csv_format);

create or replace table financial_ingestion.bronze.clienta_products (
  sku string, product_name string, category string, unit_price string, currency string, is_active string
);

copy into financial_ingestion.bronze.clienta_products
from @financial_ingestion.bronze.raw_files/Products.csv
file_format = (format_name = financial_ingestion.bronze.csv_format);

select * from FINANCIAL_INGESTION.BRONZE.CLIENTA_PRODUCTS
select * from FINANCIAL_INGESTION.BRONZE.CLIENTA_CUSTOMERS
select * from FINANCIAL_INGESTION.BRONZE.CLIENTA_ORDERS
