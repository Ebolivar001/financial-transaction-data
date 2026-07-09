truncate table financial_ingestion.silver.transaction_item;

insert into financial_ingestion.silver.transaction_item
with from_xml as (
  select
    xmlget(t.transaction_xml, 'TransactionID', 0):"$"[0]::string as transaction_id
    ,'A' as source_client
    ,xmlget(item.value, 'SKU', 0):"$"[0]::string as sku
    ,xmlget(item.value, 'Description', 0):"$"[0]::string as description
    ,try_to_number(xmlget(item.value, 'Quantity', 0):"$"[0]::string) as quantity
    ,try_to_decimal(xmlget(item.value, 'UnitPrice', 0):"$"[0]::string, 12, 1) as unit_price
  from financial_ingestion.bronze.clienta_transactions_xml t,
       lateral flatten(input => xmlget(t.transaction_xml, 'Items', 0):"$") item
  where typeof(item.value) = 'XML'
),
from_json as (
  select
    t.transaction_json:id::string as transaction_id
    ,'C' as source_client
    ,item.value:sku::string as sku
    ,item.value:description::string as description
    ,item.value:qty::number as quantity
    ,try_to_decimal(item.value:price.amount::string, 12, 1) as unit_price
  from financial_ingestion.bronze.clientc_transactions_json t,
       lateral flatten(input => t.transaction_json:items) item
),
combined as (
  select * from from_xml
  union all
  select * from from_json
),
flagged as (
  select *
    ,array_construct_compact(
      iff(sku is null or sku = '', 'missing_sku', null)
      ,iff(quantity is null, 'missing_quantity', null)
      ,iff(quantity < 0, 'negative_quantity', null)
      ,iff(unit_price is null, 'missing_unit_price', null)
      ,iff(unit_price < 0, 'negative_unit_price', null)
    ) as anomaly_reason
  from combined
)
select
  transaction_id
  ,source_client
  ,sku
  ,description
  ,quantity
  ,unit_price
  ,case when array_size(anomaly_reason) = 0 then 1 else 0 end as is_valid
  ,anomaly_reason
from flagged;
