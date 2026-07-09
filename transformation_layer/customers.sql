truncate table financial_ingestion.silver.customers;

insert into financial_ingestion.silver.customers
with combined as (
  select
    customer_id
    ,'A' as source_client
    ,first_name
    ,last_name
    ,email
    ,loyalty_tier as tier
    ,signup_source
    ,is_active
  from financial_ingestion.bronze.clienta_customers
  union all
  select
    customer_id
    ,'C' as source_client
    ,split_part(customer_name, ' ', 1) as first_name
    ,nullif(trim(regexp_replace(customer_name, '^[^ ]+ ?', '')), '') as last_name
    ,email
    ,segment as tier
    ,null as signup_source
    ,is_active
   from financial_ingestion.bronze.clientc_customers
),
ranked as (
  select *
    ,row_number() over (partition by source_client, customer_id order by customer_id) as cust_rank
  from combined
),
flagged as (
  select *
    ,(email is not null and email != '' and email rlike '^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\\.[A-Za-z]{2,}$') as email_valid_calc
    ,array_construct_compact(
      iff(customer_id is null or customer_id = '', 'missing_customer_id', null)
      ,iff(first_name is null or first_name = '', 'missing_first_name', null)
      ,iff(email is null or email = '', 'missing_email', null)
      ,iff(email is not null and email != '' and not (email rlike '^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\\.[A-Za-z]{2,}$'), 'invalid_email', null)
    ) as anomaly_reason
  from ranked
  where cust_rank = 1
)
select
  customer_id
  ,source_client
  ,first_name
  ,last_name
  ,email
  ,email_valid_calc
  ,tier
  ,signup_source
  ,case when try_to_boolean(regexp_replace(is_active, '\\s*<--.*', '')) then 1 else 0 end as is_active
  ,null as extra_attributes
  ,case when array_size(anomaly_reason) = 0 then 1 else 0 end as is_valid
  ,anomaly_reason
from flagged;