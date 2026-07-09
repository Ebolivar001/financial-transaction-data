-- ============================================================
-- CLIENT A — XML transactions (fragmented across 7 files)
-- ============================================================

-- read whole file as one text field, no splitting
create or replace file format financial_ingestion.bronze.full_file_format
  type = csv
  field_delimiter = '\x01'
  record_delimiter = '\x02'
  escape_unenclosed_field = none;

-- raw text, one row per client a file
create or replace table financial_ingestion.bronze.clienta_xml_fragments (
  file_name string,
  raw_text string
);

copy into financial_ingestion.bronze.clienta_xml_fragments (file_name, raw_text)
from (
  select metadata$filename, $1
  from @financial_ingestion.bronze.raw_files
)
pattern = '.*ClientA_Transactions_.*'
file_format = (format_name = financial_ingestion.bronze.full_file_format)
on_error = 'ABORT_STATEMENT';

-- merge the 7 fragments into one xml doc, strip file markers and dupe SalesData tags
create or replace table financial_ingestion.bronze.clienta_xml_assembled as
select
  '<SalesData>' ||
  regexp_replace(
    regexp_replace(
      listagg(raw_text, '') within group (order by file_name),
      '-{5}\\s*(START|END)\\s+OF\\s+FILE[^\\n]*-{5}',
      ''
    ),
    '</?SalesData[^>]*>',
    ''
  ) ||
  '</SalesData>' as full_xml_text
from financial_ingestion.bronze.clienta_xml_fragments;

-- check it starts/ends clean
select
  left(full_xml_text, 200) as start_file,
  right(full_xml_text, 200) as end_file,
  length(full_xml_text) as total_chars
from financial_ingestion.bronze.clienta_xml_assembled;

-- one row per transaction, drop the blank text nodes
create or replace table financial_ingestion.bronze.clienta_transactions_xml as
select
  t.value as transaction_xml
from financial_ingestion.bronze.clienta_xml_assembled a,
     lateral flatten(input => parse_xml(a.full_xml_text):"$") t
where typeof(t.value) = 'XML';

-- should be 46
select count(*) from financial_ingestion.bronze.clienta_transactions_xml;
select * from financial_ingestion.bronze.clienta_transactions_xml;
