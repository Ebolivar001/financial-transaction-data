truncate table financial_ingestion.silver.transactions;

insert into financial_ingestion.silver.transactions
with from_xml as (
  select
    xmlget(transaction_xml, 'TransactionID', 0):"$"[0]::string as transaction_id
    ,'A' as source_client
    ,xmlget(xmlget(transaction_xml, 'Order', 0), 'OrderID', 0):"$"[0]::string as order_id
    ,xmlget(xmlget(xmlget(transaction_xml, 'Order', 0), 'Customer', 0), 'CustomerID', 0):"$"[0]::string as customer_id
    ,xmlget(xmlget(transaction_xml, 'Payment', 0), 'Method', 0):"$"[0]::string as payment_method
    ,try_to_decimal(xmlget(xmlget(transaction_xml, 'Payment', 0), 'Amount', 0):"$"[0]::string, 12, 2) as payment_amount
    ,try_to_date(xmlget(xmlget(transaction_xml, 'Order', 0), 'OrderDate', 0):"$"[0]::string) as transaction_date
    ,transaction_xml as extra_attributes
  from financial_ingestion.bronze.clienta_transactions_xml
),
from_json as (
  select
    transaction_json:id::string as transaction_id
    ,'C' as source_client
    ,transaction_json:order.id::string as order_id
    ,transaction_json:order.customer.id::string as customer_id
    ,transaction_json:payment.method::string as payment_method
    ,try_to_decimal(transaction_json:payment.total::string, 12, 1) as payment_amount
    ,try_to_date(transaction_json:order.date::string) as transaction_date
    ,transaction_json as extra_attributes
  from financial_ingestion.bronze.clientc_transactions_json
),
combined as (
  select * from from_xml
  union all
  select * from from_json
),
ranked as (
  select *
    ,row_number() over (partition by source_client, transaction_id order by transaction_id) as txn_rank
  from combined
),
flagged as (
  select *
    ,array_construct_compact(
      iff(transaction_id is null or transaction_id = '', 'missing_transaction_id', null)
      ,iff(order_id is null or order_id = '', 'missing_order_id', null)
      ,iff(customer_id is null or customer_id = '', 'missing_customer_id', null)
      ,iff(payment_method is null or payment_method = '', 'missing_payment_method', null)
      ,iff(payment_amount is null, 'missing_payment_amount', null)
      ,iff(payment_amount < 0, 'negative_amount', null)
      ,iff(transaction_date is null, 'missing_transaction_date', null)
      ,iff(txn_rank > 1, 'duplicate_transaction_id', null)
    ) as anomaly_reason
  from ranked
)
select
  transaction_id
  ,source_client
  ,order_id
  ,customer_id
  ,payment_method
  ,payment_amount
  ,transaction_date
  ,extra_attributes
  ,case when array_size(anomaly_reason) = 0 then 1 else 0 end as is_valid
  ,anomaly_reason
from flagged;