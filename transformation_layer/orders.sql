truncate table financial_ingestion.silver.orders;

insert into financial_ingestion.silver.orders
with combined as (
  select
    order_id
    ,customer_id
    ,order_date
    ,order_status
    ,channel
    ,'A' as source_client
  from financial_ingestion.bronze.clienta_orders
  union all
  select
    order_id
    ,customer_id
    ,order_date
    ,order_status
    ,null as channel
    ,'C' as source_client
  from financial_ingestion.bronze.clientc_orders
),
ranked as (
  select *
    ,row_number() over (partition by source_client, order_id order by order_id) as ord_rank
  from combined
),
flagged as (
  select *
    ,try_to_date(order_date) as order_date_parsed
    ,regexp_replace(order_status, '\\s*<--.*', '') as order_status_clean
    ,regexp_replace(channel, '\\s*<--.*', '') as channel_clean
    ,array_construct_compact(
      iff(order_id is null or order_id = '', 'missing_order_id', null)
      ,iff(customer_id is null or customer_id = '', 'missing_customer_id', null)
      ,iff(order_date is null or order_date = '', 'missing_order_date', null)
      ,iff(order_date is not null and order_date != '' and order_date_parsed is null, 'invalid_order_date_format', null)
    ) as anomaly_reason
  from ranked
  where ord_rank = 1
)
select
  order_id
  ,source_client
  ,customer_id
  ,order_date_parsed
  ,order_status_clean as order_status
  ,channel_clean as channel
  ,case when array_size(anomaly_reason) = 0 then 1 else 0 end as is_valid
  ,anomaly_reason
from flagged;