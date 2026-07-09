# Financial Data Ingestion & Canonical Modeling

Snowflake exercise: ingest transaction data from three clients (XML, JSON, CSV), model it into one canonical structure, and handle the data quality issues along the way. Everything below is SQL

## What's actually in the source data

The sample data is organized in the following order:

- **Client A** — transactions as XML, fragmented across 7 files (`ClientA_Transactions_1.xml` ... `_7.xml`, one of them saved as `.txt`) and 3CSVs for customers/orders/products.
- **"Client B" folder** — actually Client C. The folder name is wrong; every file inside it (the JSON and its 4 CSVs) identifies itself as `clientC_*` in its own content. I went with what the files say about themselves, not the folder name.

Full breakdown of anomalies and how each was handled is in [`notes.md`](./notes.md).

## Architecture

Medallion, 3 layers:

```
raw_ingestion/      -> bronze: data as close to the source as possible
transformation_layer/ -> silver: cleaned, unified model, one row schema for both clients
reporting_layer/    -> gold: business-facing views on top of silver
```

`canonical/` holds the DDL for the silver tables (customers, products, orders, transactions, transaction_item, payments) — same shape regardless of which client the data came from, with a `source_client` column to tell them apart.

Nothing gets silently dropped in the fact tables. Every silver table has `is_valid` and `anomaly_reason` — bad data gets flagged, not deleted, so it stays auditable.

## How to run

Order matters:

1. Upload the 15 source files to the `bronze.raw_files` stage in Snowsight (Data > Load Files into a Stage). `PUT` only works from a local client, not the browser, so this one step is done through the UI — everything else is SQL.
2. `raw_ingestion/` — run `initial_setup.sql` first, then `clienta_xml.sql`, `clientc_json.sql`, `clienta_csv.sql`, `clientc_csv.sql` (order between these last 4 doesn't matter).
3. `canonical/canonical_ddl.sql`
4. `transformation_layer/` — run all 6 files (products, customers, orders, transactions, transaction_item, payments).
5. `reporting_layer/` — the 4 gold views, run any order.

## Folders

| Folder | Contents |
|---|---|
| `raw_ingestion/` | stage setup, file formats, XML/JSON reassembly, CSV loads |
| `canonical/` | silver table DDL |
| `transformation_layer/` | bronze -> silver, one file per table |
| `reporting_layer/` | gold views for reporting |
| `notes.md` | anomalies found and how each was handled |
