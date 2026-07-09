truncate table financial_ingestion.silver.payments;

insert into financial_ingestion.silver.payments
with ranked as (
  select *
    ,row_number() over (partition by payment_id order by payment_id) as pay_rank
  from financial_ingestion.bronze.clientc_payments
),
flagged as (
  select *
    ,try_to_decimal(amount, 12, 2) as amount_parsed
    ,regexp_replace(status, '\\s*<--.*', '') as status_clean
    ,array_construct_compact(
      iff(payment_id is null or payment_id = '', 'missing_payment_id', null)
      ,iff(order_id is null or order_id = '', 'missing_order_id', null)
      ,iff(try_to_decimal(amount,12,2) is null, 'invalid_amount', null)
      ,iff(try_to_decimal(amount,12,2) < 0 and regexp_replace(status, '\\s*<--.*', '') != 'REFUNDED', 'unexpected_negative_amount', null)
      ,iff(pay_rank > 1, 'duplicate_payment_id', null)
    ) as anomaly_reason
  from ranked
)
select
  payment_id
  ,'C' as source_client
  ,order_id
  ,payment_method
  ,amount_parsed
  ,currency
  ,status_clean as status
  ,case when array_size(anomaly_reason) = 0 then 1 else 0 end as is_valid
  ,anomaly_reason
from flagged;