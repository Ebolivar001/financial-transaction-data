-- ============================================================
-- GOLD TABLE: product_sales_summary
-- Units sold and revenue per product
-- ============================================================
create or replace view financial_ingestion.gold.product_sales_summary as
select
  transaction_item.source_client,
  transaction_item.sku,
  products.product_name,
  products.category,
  sum(transaction_item.quantity) as units_sold,
  sum(transaction_item.quantity * transaction_item.unit_price) as total_revenue
from financial_ingestion.silver.transaction_item
left join financial_ingestion.silver.products
  on transaction_item.sku = products.sku
  and transaction_item.source_client = products.source_client
where transaction_item.is_valid = 1
group by transaction_item.source_client, transaction_item.sku, products.product_name, products.category;