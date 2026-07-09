-- ============================================================
-- BRONZE to SILVER: products
-- ============================================================

truncate table financial_ingestion.silver.products;

insert into financial_ingestion.silver.products
with combined as (
  select
    sku
    ,'A' as source_client
    ,product_name
    ,category
    ,unit_price
    ,currency
    ,is_active
  from financial_ingestion.bronze.clienta_products
  union all
  select
    sku
    ,'C' as source_client
    ,product_name
    ,category
    ,unit_price
    ,currency
    ,is_active
  from financial_ingestion.bronze.clientc_products
),
ranked as (
  select
    sku
    ,source_client
    ,product_name
    ,category
    ,unit_price
    ,currency
    ,is_active
    ,row_number() over (partition by source_client, sku order by sku) as sku_rank
  from combined
),
flagged as (
  select *
    ,array_construct_compact(
      iff(sku is null or sku = '', 'missing_sku', null)
      ,iff(try_to_decimal(unit_price,12,2) < 0, 'negative_price', null)
    ) as anomaly_reason
  from ranked
  where sku_rank = 1
)
select
  sku
  ,source_client
  ,product_name
  ,category
  ,try_to_decimal(unit_price, 12, 1) as unit_price
  ,currency
  ,case when try_to_boolean(regexp_replace(is_active, '\\s*<--.*', '')) then 1 else 0 end as is_active
  ,case when array_size(anomaly_reason) = 0 then 1 else 0 end as is_valid
  ,anomaly_reason
from flagged;
