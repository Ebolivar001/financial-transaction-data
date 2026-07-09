-- ============================================================
-- GOLD TABLE: refund_summary
-- How many refunds per client, and how much money do they represent?
-- ============================================================
create or replace view financial_ingestion.gold.refund_summary as
select
  source_client,
  count(*) as total_payments,
  sum(iff(status = 'REFUNDED', 1, 0)) as refunded_payments,
  sum(iff(status = 'REFUNDED', amount, 0)) as total_refunded_amount
from financial_ingestion.silver.payments
where is_valid = 1
group by source_client;