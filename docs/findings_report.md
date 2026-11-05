# Findings Report

## Status

This report records the results documented from initial profiling and data-quality checks on the DataCo Smart Supply Chain dataset. The source CSV has 180,519 data rows and 53 columns. These findings describe the current staging data; they are not claims about a broader population.

The implemented SQL work currently covers database/staging setup, import, profiling, and data-quality checks (`sql/01` through `sql/04`). The later cleaning, delivery analysis, schema, inventory, advanced analysis, supplier/logistics, optimization, and reusable-view scripts (`sql/05` through `sql/12`) are present as empty placeholders. No normalized schema or downstream analytical findings are yet documented.

## Profiling Results

| Check | Result recorded |
|---|---:|
| Source rows | 180,519 |
| Source columns | 53 |
| Distinct order IDs | 65,752 |
| Distinct order-item IDs | 180,519 |
| Distinct customer IDs | 20,652 |
| Distinct product IDs | 118 |
| Duplicate non-empty order-item IDs | 0 |

The inspected important fields had no SQL `NULL` or empty/whitespace values. Inspected numeric values matched the expected numeric syntax, and the inspected date values matched the expected text format. These were focused checks, not a complete semantic validation of every column or calendar date.

## Consistency and Cardinality

- `Customer Id` and `Order Customer Id` matched in all rows checked. No order was associated with multiple distinct customers, and no conflicts were found across the nine inspected order-level attributes.
- No missing or mismatched product identifiers were found between `Order Item Cardprod Id` and `Product Card Id` in the checks recorded. No product/category/department mapping conflicts or missing product categories were found in the inspected mappings.
- The order-cardinality check found 65,752 represented orders, between 1 and 5 item rows per order, and no orders with repeated or missing item IDs.
- Delivery-status counts matched the corresponding `Late_delivery_risk` counts in the checked comparison. This agreement does not independently validate the source's business definition.

These are source-row consistency checks. They do not replace primary-key and foreign-key validation in a normalized schema.

## Dates and Numeric Measures

- Initial date profiling reported 65,752 distinct non-empty order-date values and 63,701 distinct non-empty shipping-date values.
- A chronology query initially encountered a parsing issue under the PostgreSQL session's default date style. After explicitly parsing the source format, no nonblank parsed rows showed shipping earlier than ordering. This does not establish that every date is valid or present.
- The inspected quantities were neither negative nor zero; inspected sales and order-item product prices were not negative.
- `Order Item Profit Ratio` ranged from `-2.75` to `0.50`, averaged approximately `0.1206`, and had 33,784 negative, 1,177 zero, and 145,558 positive rows (180,519 total).
- A read-only audit of the local source CSV found that `Order Profit Per Order` and `Benefit per order` contain identical text on all 180,519 rows. Each field has multiple distinct values within 45,902 orders and one distinct value within 19,850 orders. Thus, in this extract they are identical row-level source values, but they are not constant across every order's item rows. This observed pattern does not establish either field's business meaning or economic grain; neither should be treated as an order-level total or summed until those are defined.
- `Order Item Profit Ratio` is a row-level source field, and the profiling SQL explores its distribution alongside profit values. The recorded findings do not establish a validated profit formula or an aggregation rule for the ratio or either profit field.
- Some orders contain multiple item-level profit ratios; order `10004` was an inspected example. Negative ratios have not been classified as errors and no source values were changed or removed.

The order-level variation checks for `Order Profit Per Order` and `Benefit per order` are present in `sql/04_data_quality_checks.sql`, but their execution output is not committed. The section comment calls them “order-level financial measures”; that is a check label, not evidence that either field has order-level business grain. The SQL checks each field's within-order variation separately and do not compare the two columns for equality. `sql/03_data_profiling.sql` checks their numeric syntax and explores profit-ratio values, but does not establish their relationship or aggregation. The counts and row-wise equality above are independently confirmed by a read-only audit of the local CSV; the scripts do not document or persist these result counts.

## Interpretation

The checks support treating the source as order-item-grain data and support the proposed entity relationships as a starting point. They do not establish final schema constraints, financial aggregation rules, causal explanations for delivery outcomes, or supplier/inventory performance.

Metric definitions and their current status are in [metric_definitions.md](./metric_definitions.md). Remaining assumptions and validation work are in [assumptions_and_limitations.md](./assumptions_and_limitations.md).

## Next Work

1. Validate candidate keys and foreign-key relationships for the proposed entities.
2. Resolve remaining product/category/department identifier and schema decisions.
3. Confirm measure meanings and aggregation rules before reporting financial or delivery KPIs.
4. Implement and test the normalized schema, then execute the planned analysis scripts.
5. Add results and recommendations only after the relevant queries have been run and checked.
