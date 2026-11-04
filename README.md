# Supply Chain & Operations Intelligence

A PostgreSQL and SQL portfolio project exploring order, delivery, and supply-chain data from the DataCo Smart Supply Chain dataset. The current implemented work is focused on staging setup, import, profiling, and data-quality checks; downstream analysis and schema work remain in progress.

## Project Goals

- Validate source data and document its grain and limitations.
- Develop defensible delivery, sales, and profitability metrics.
- Explore operational patterns only when supported by the available data.
- Build reusable SQL analyses and, later, evaluate query performance.

Supplier performance and inventory risk are questions for future work: the current dataset does not establish supplier identifiers or inventory/replenishment history.

## Repository

- `data/` — source-data instructions and local datasets
- `docs/` — business context, assumptions, proposed model, data dictionary, metrics, and findings
- `sql/` — setup, import, profiling, validation, and planned analysis scripts
- `tests/` — SQL data-quality test work
- `references/` — SQL patterns
- `results/` — reserved for reviewed outputs

## Current SQL Progress

Run the populated scripts in order:

1. `sql/01_database_setup.sql` — creates `supply_chain_analytics` and the raw text staging table.
2. `sql/02_import_dataco.sql` — guarded `psql` `\copy` import from the local source CSV.
3. `sql/03_data_profiling.sql` — read-only profiling.
4. `sql/04_data_quality_checks.sql` — read-only consistency and anomaly checks.

Scripts `sql/05` through `sql/12` are currently placeholders, not completed analyses. Findings recorded so far are summarized in [docs/findings_report.md](./docs/findings_report.md).

## Getting Started

Prerequisites: PostgreSQL and the `psql` client. The setup script must be run with a role permitted to create a database if `supply_chain_analytics` does not already exist. From PowerShell at the repository root:

```powershell
psql -X -W -U postgres -v ON_ERROR_STOP=1 -d postgres -f 'sql\01_database_setup.sql'
psql -X -W -U postgres -v ON_ERROR_STOP=1 -v replace_staging=on -d supply_chain_analytics -f 'sql\02_import_dataco.sql'
```

The import script defaults to doing nothing. `-v replace_staging=on` explicitly authorizes replacing the staging table contents; review existing data before using it. The script uses client-side `\copy` and currently names this workspace's local CSV path. If the repository is elsewhere, update only that local path in `sql/02_import_dataco.sql`.

Then connect to `supply_chain_analytics` in a SQL editor and run `sql/03_data_profiling.sql`, followed by `sql/04_data_quality_checks.sql`. These files contain regular SQL queries; setup and import use `psql` commands and are not plain SQL-editor scripts.

See [data/README.md](./data/README.md) for source and data-handling notes.

## Documentation

- [Business context](./docs/business_context.md)
- [Assumptions and limitations](./docs/assumptions_and_limitations.md)
- [ER diagram](./docs/er_diagram.md)
- [Data dictionary](./docs/data_dictionary.md)
- [Source-to-entity mapping](./docs/source_to_entity_mapping.md)
- [Metric definitions](./docs/metric_definitions.md)
- [Findings report](./docs/findings_report.md)

## Technology

- PostgreSQL
- SQL
- Visual Studio Code
- Git and GitHub

## Author

Sanskruti Joshi
