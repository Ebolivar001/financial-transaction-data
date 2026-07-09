-- ============================================================
-- CLIENT C — JSON transactions (labeled "Client B" folder, actually Client C)
-- ============================================================

-- raw text load for the json file, same trick as the xml fragments
create or replace table financial_ingestion.bronze.clientc_json_raw (
  file_name string,
  raw_text string
);

copy into financial_ingestion.bronze.clientc_json_raw (file_name, raw_text)
from (
  select metadata$filename, $1
  from @financial_ingestion.bronze.raw_files
)
pattern = '.*transactions\\.json'
file_format = (format_name = financial_ingestion.bronze.full_file_format)
on_error = 'ABORT_STATEMENT';

-- should be 1 row
select *
from financial_ingestion.bronze.clientc_json_raw;

-- strip file markers and // comments (invalid in standard json)
create or replace table financial_ingestion.bronze.clientc_json_clean as
select
  regexp_replace(
    regexp_replace(raw_text, '-{5}\\s*(START|END)\\s+OF\\s+FILE[^\\n]*-{5}', ''),
    '//[^\\n]*',
    ''
  ) as clean_json_text
from financial_ingestion.bronze.clientc_json_raw;

-- check it parses now
select parse_json(clean_json_text) as json_variant
from financial_ingestion.bronze.clientc_json_clean;


-- one row per transaction from the transactions array
create or replace table financial_ingestion.bronze.clientc_transactions_json as
select
  t.value as transaction_json
from financial_ingestion.bronze.clientc_json_clean c,
     lateral flatten(input => parse_json(c.clean_json_text):"transactions") t;

-- how many did we get
select count(*) from financial_ingestion.bronze.clientc_transactions_json;
select * from financial_ingestion.bronze.clientc_transactions_json;