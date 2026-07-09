# Notes on anomalies found and how I handled them

While going through the source files I found a lot more going on than the exercise doc mentioned ("three sample files"). Here's what I actually found and the decisions I made.

## Structural stuff before I even got to the data itself

**"Client B" folder is actually Client C.** The folder is named "Client B" but every file inside it (`transactions.json`, and the 4 CSVs) opens with a header comment identifying itself as `clientC_*`, and the JSON body literally has `"client": "ClientC"`. I trusted the content over the folder name, the `client` field is what the source system actually said about itself.

**Client A's XML isn't one file, it's seven.** `ClientA_Transactions_1.xml` through `_7.xml` (plus a `_4.txt` that's actually XML with the wrong extension) are fragments of a single document, not 7 separate ones. Only file 1 and file 7 had their own `<SalesData>` open/close tags — and both had a *complete* pair, which meant just concatenating them gave me "more than one document" errors from `PARSE_XML`. Fix: strip every `<SalesData>` tag from all 7 fragments after joining them, then wrap the whole thing in one clean root myself. That's in `raw_ingestion/clienta_xml.sql`.

**The JSON isn't valid JSON as-is.** It has `//` comments (`"id": "C-TXN-3001",   // duplicate`) and file marker lines (`----- START OF FILE ... -----`) baked in. Standard JSON doesn't allow comments, so `PARSE_JSON` fails until I strip both with regex first.

**CSV files have inline comments stuck to the last column.** This one took me a while to catch. Rows like:
```
C-SKU-999,Unknown Product,Unknown,0.00,USD,false          <-- anomaly
```
Since there's no comma before `<-- anomaly`, it becomes part of whatever the last column is (`is_active`, `channel`, `order_status`, `status` — depends on the file). It broke `TRY_TO_BOOLEAN` and a status comparison I had for refunds before I noticed and added a `REGEXP_REPLACE` to strip it off.

## Data-level anomalies

**Duplicates.** I split these into two groups and handled them differently on purpose:
- `products`, `customers`, `orders` — these are reference/master data, so an exact duplicate isn't useful. I deduplicate silently (`ROW_NUMBER()` + keep the first).
- `transactions`, `transaction_item`, `payments` — these are financial facts. A duplicate transaction or payment is something you'd actually want to be able to point to and say "this happened twice," so I keep both rows and just flag the extra one with `duplicate_transaction_id` / `duplicate_payment_id` in `anomaly_reason`.

**Nulls / missing required fields** (transaction ID, order ID, customer ID, SKU, email, etc.) I flagged with a specific reason string, not dropped. Same logic everywhere: `is_valid` is a derived flag, `array_size(anomaly_reason) = 0`.

**Negative amounts** I flagged as `negative_amount` / `negative_quantity` in most places, but I made an exception for `payments`: if `status = 'REFUNDED'`, a negative amount is expected, not an error. I only flag it there if it's negative *and* not marked as a refund.

**Invalid emails**  checked with a regex (`^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}$`), catches stuff like `invalid-email`, `noemail@`, `sam@@example..com`. Flagged, not dropped, I keep the original value and just mark `is_email_valid = false`.

**Orphan references** (a customer_id or sku on a transaction that doesn't exist in the master tables, e.g. `CUST-A-9999`)  I didn't build hard foreign keys for these. In the gold layer I used `LEFT JOIN` instead of `JOIN` so an orphaned sku still shows up in `product_sales_summary` with a null product name, instead of silently vanishing from the report.

## Why flag instead of delete everywhere

Every silver table has the same two columns: `is_valid` (1/0) and `anomaly_reason` (array of strings). Nothing gets silently dropped in the fact tables and the point was to make bad data visible and auditable, not disappear it. `gold/data_quality_summary.sql` rolls this up so you can see at a glance how many rows per table got flagged.
