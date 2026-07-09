-- ============================================================
-- GOLD TABLE: revenue_overview
-- How is the business performing month over month, per client?
-- ============================================================
create or replace view financial_ingestion.gold.revenue_overview as
select
  source_client,
  date_trunc('month', transaction_date) as month,
  count(*) as transaction_count,
  sum(payment_amount) as total_revenue,
  round(avg(payment_amount), 2) as avg_order_value
from financial_ingestion.silver.transactions
where is_valid = 1
group by source_client, date_trunc('month', transaction_date)
order by month, source_client;