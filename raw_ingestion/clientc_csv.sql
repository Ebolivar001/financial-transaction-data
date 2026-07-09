-- ============================================================
-- CLIENT C — CSV reference tables (customers, orders, payments, products)
-- ============================================================

create or replace table financial_ingestion.bronze.clientc_customers (
  customer_id string, customer_name string, email string, segment string, is_active string
);

copy into financial_ingestion.bronze.clientc_customers
from @financial_ingestion.bronze.raw_files/Customer.CSV
file_format = (format_name = financial_ingestion.bronze.csv_format);

create or replace table financial_ingestion.bronze.clientc_orders (
  order_id string, customer_id string, order_date string, order_status string
);

copy into financial_ingestion.bronze.clientc_orders
from @financial_ingestion.bronze.raw_files/Order.csv
file_format = (format_name = financial_ingestion.bronze.csv_format);

create or replace table financial_ingestion.bronze.clientc_payments (
  payment_id string, order_id string, payment_method string, amount string, currency string, status string
);

copy into financial_ingestion.bronze.clientc_payments
from @financial_ingestion.bronze.raw_files/Payments.csv
file_format = (format_name = financial_ingestion.bronze.csv_format);

create or replace table financial_ingestion.bronze.clientc_products (
  sku string, product_name string, category string, unit_price string, currency string, is_active string
);

copy into financial_ingestion.bronze.clientc_products
from @financial_ingestion.bronze.raw_files/Product.csv
file_format = (format_name = financial_ingestion.bronze.csv_format);

-- drop the trailing "END OF FILE" marker row that leaked into each table
delete from financial_ingestion.bronze.clientc_customers where customer_id ilike '%END OF FILE%';
delete from financial_ingestion.bronze.clientc_orders where order_id ilike '%END OF FILE%';
delete from financial_ingestion.bronze.clientc_payments where payment_id ilike '%END OF FILE%';
delete from financial_ingestion.bronze.clientc_products where sku ilike '%END OF FILE%';

select * from financial_ingestion.bronze.clientc_customers;
select * from financial_ingestion.bronze.clientc_orders;
select * from financial_ingestion.bronze.clientc_payments;
select * from financial_ingestion.bronze.clientc_products;