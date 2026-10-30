# Dataset Documentation

## Primary Dataset

- **Name:** DataCo Smart Supply Chain Dataset
- **Source:** [Kaggle — DataCo Smart Supply Chain](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)
- **Use in this project:** Explore order, delivery, customer, product, geographic, and shipping data.

The downloaded local files are `DataCoSupplyChainDataset.csv`, `DescriptionDataCoSupplyChain.csv`, and `tokenized_access_logs.csv`. The primary analysis uses `DataCoSupplyChainDataset.csv`; the companion description file supplies source field descriptions.

## Source and Handling

- Raw files belong under `data/raw/`; the root `.gitignore` excludes `data/raw/` and `data/processed/`.
- Do not edit, rename, move, or publish the original CSV as part of analysis.
- The current primary CSV has 53 header fields and 180,519 data rows. A read-only parse found Windows-1252 encoding; the import script specifies that encoding. These are local-file observations, not proof of a successful database import.
- The staging table retains the source column names and loads all fields as `TEXT` for profiling.
- The source includes customer-related fields. Keep the database local and do not commit exports, query results, or copied customer values.

## PostgreSQL Import

The reproducible setup and import commands are in the root [README](../README.md). The relevant scripts are `sql/01_database_setup.sql` and `sql/02_import_dataco.sql`; the project database is `supply_chain_analytics`.

The import uses client-side `\copy`, so the local `psql` client must be able to read the CSV. The import script currently contains this workspace's absolute CSV path; when using a different checkout, update that path in the script. It defaults to no import. Passing `-v replace_staging=on` explicitly permits a transactional truncate-and-reload of `staging.dataco_raw`; inspect the current staging table before enabling it.

The import treats only the exact unquoted `\N` field as SQL `NULL`; ordinary empty fields remain empty text. The current local CSV has no exact `\N` field.
