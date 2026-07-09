-- ============================================================
-- GOLD TABLE: data_quality_summary
-- How much of each silver table is clean vs. flagged as anomalous?
-- ============================================================
create or replace view financial_ingestion.gold.data_quality_summary as
select
  table_name,
  total_rows,
  flagged_rows
from (
  select 'customers' as table_name, count(*) as total_rows, sum(iff(is_valid = 1, 0, 1)) as flagged_rows from financial_ingestion.silver.customers
  union all
  select 'products', count(*), sum(iff(is_valid = 1, 0, 1)) from financial_ingestion.silver.products
  union all
  select 'orders', count(*), sum(iff(is_valid = 1, 0, 1)) from financial_ingestion.silver.orders
  union all
  select 'transactions', count(*), sum(iff(is_valid = 1, 0, 1)) from financial_ingestion.silver.transactions
  union all
  select 'transaction_item', count(*), sum(iff(is_valid = 1, 0, 1)) from financial_ingestion.silver.transaction_item
  union all
  select 'payments', count(*), sum(iff(is_valid = 1, 0, 1)) from financial_ingestion.silver.payments
);