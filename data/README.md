
# Dataset Documentation

## Primary Dataset

- **Name:** DataCo Smart Supply Chain Dataset
- **Source:** [Kaggle — DataCo Smart Supply Chain](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)
- **Purpose:** Explore order processing, delivery performance, customer orders, and supply chain operations.

## Files Downloaded

- `DataCoSupplyChainDataset.csv`
- `DescriptionDataCoSupplyChain.csv`
- `tokenized_access_logs.csv`

## Data Handling

- Original files are stored locally in `data/raw/`.
- Raw files are not committed to GitHub by default.
- The root `.gitignore` excludes files under `data/raw/` and `data/processed/`.
- Do not edit, rename, move, or publish the original CSV. The import reads it
  directly and loads a separate PostgreSQL staging table.
- The staging table includes customer-related fields. Keep the database local
  and do not commit exports, query results, or copied customer values.

## PostgreSQL Staging Import

The primary source file is `data/raw/DataCoSupplyChainDataset.csv`. A
read-only CSV parse verified 53 header fields and 53 fields in every data row
(180,519 data rows in the current local file; this is not an import result).
The file is not valid UTF-8; it parses as Windows-1252, which is the encoding
specified by the import script. The staging table retains the source column
labels and initially stores every field as `TEXT`.

Run `sql/01_database_setup.sql` with `psql` connected to the default
`postgres` database. Then run `sql/03_import_dataco.sql` with `psql` connected
to `supply_chain_db`. The import uses client-side `\copy`, so the local client
must be able to read the CSV; the PostgreSQL server does not need direct access
to the local file. The script defaults to doing nothing. Passing
`-v replace_staging=on` explicitly permits it to replace rows in
`staging.dataco_raw` inside a transaction. Review the existing staging data
before enabling this option.

From a PowerShell terminal opened at the repository root, run these commands
in order:

```powershell
psql -X -W -v ON_ERROR_STOP=1 -d postgres -f 'sql\01_database_setup.sql'
psql -X -W -v ON_ERROR_STOP=1 -v replace_staging=on -d supply_chain_db -f 'sql\03_import_dataco.sql'
```

The first script creates `supply_chain_db` only if it does not exist, connects
to it, and creates the staging schema/table if needed. It requires permission
to create a database if one is not already present. `-W` prompts for a
password without placing it in the command or a script. If local `psql`
defaults differ from the VS Code connection profile, supply matching `-h`,
`-p`, and `-U` options, but never put a password in the command.

The import script currently points to this workspace's source path. If the
project is moved, update only the local path in the `\copy` command; do not
change the raw source file. `NULL E'\\N'` reserves the exact unquoted `\N`
field as SQL NULL so ordinary empty fields remain empty text; the current CSV
contains no exact `\N` field.

After a successful import, run `sql/02_data_profiling.sql` in a query editor
connected to `supply_chain_db`. Its row count, column count, missing-value,
identifier, duplicate, date-shape, numeric-format, and categorical-value
checks are validation results; no row-count target is assumed here.

If using a VS Code PostgreSQL import UI instead of `psql`, choose the local
CSV, enable header-row handling, use Windows-1252 encoding, map all 53 fields
in source order to `staging.dataco_raw`, retain them as text, and use a replace
or clear-and-load mode only after reviewing the existing staging rows. Do not
use a server-side `COPY` path unless the PostgreSQL server itself can access
that file.