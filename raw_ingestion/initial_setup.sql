-- ============================================================
--  Initial setup — database, schemas, warehouse, and stage
-- ============================================================

-- Project database
create database if not exists financial_ingestion;
create schema if not exists financial_ingestion.bronze;
create schema if not exists financial_ingestion.silver;
create schema if not exists financial_ingestion.gold;

use database financial_ingestion;
use schema bronze;

-----------------------------------------------------------------------

-- Compute warehouse for loading and transformation
create warehouse if not exists ingestion_wh
  with warehouse_size = 'xsmall'   -- small enough for this data volume
  auto_suspend = 60  -- avoid idle credit burn
  auto_resume = true; 

use warehouse ingestion_wh;

-------------------------------------------------------------------

-- Internal stage for uploading source files before loading into tables
create stage if not exists raw_files
  directory = (enable = true);

-------------------------------------------------------------------

-- Files were uploaded manually via UI and this below is to verify that they were uploaded properly

use database financial_ingestion;
use schema bronze;

select relative_path, size, last_modified
from directory(@raw_files)
order by relative_path;

  