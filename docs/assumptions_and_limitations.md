## Initial Data Inspection

The initial sample suggests that the dataset contains order-item-level records, with order, customer, product, sales, and shipping attributes represented in the same table.

The initial questions included whether `Order Item Id` uniquely identifies each record, whether multiple order items can share an `Order Id`, whether product-category identifiers are missing, whether shipping dates are valid, whether delivery status agrees with `Late_delivery_risk`, and whether sales and profit measures should be aggregated at the order-item or order level.

These questions have been investigated through initial profiling and subsequent data-quality checks. Some checks have been completed, while primary-key and foreign-key validation and business-level metric interpretation remain outstanding.

## Initial Profiling Findings

The source CSV contains 180,519 data rows and 53 columns. Initial profiling established the following:

- 65,752 distinct order IDs.
- 180,519 distinct order-item IDs, matching the total row count.
- 20,652 distinct customer IDs.
- 118 distinct product IDs.
- No duplicate non-empty order-item IDs were returned by the initial duplicate check.
- The inspected important fields contained no SQL NULLs or empty/whitespace values.
- The inspected numerical fields contained no values that failed the expected numeric syntax checks.
- The inspected date fields matched the expected text format.
- The count of rows classified as `Late delivery` matched the count with `Late_delivery_risk = 1`.

These are preliminary findings. Identifier uniqueness and relationship integrity must still be validated against the proposed normalized schema.

## Additional Data-Quality Findings

### Identifier and Relationship Consistency

A subsequent check found no mismatches between `Customer Id` and `Order Customer Id`. No orders were found associated with multiple distinct customer IDs, and no conflicting values were identified across the nine inspected order-level attributes.

The product identifier mapping check found zero missing identifiers and zero mismatches between `Order Item Cardprod Id` and `Product Card Id`.

The inspected product, category, and department mappings showed no conflicting names for the same identifier, no products mapped to multiple categories or departments, and no products with missing categories. A foreign-key check also returned no unmatched nonblank order-item product identifiers when compared with the distinct product identifiers in the staging dataset.

These results support the proposed entity relationships but do not replace complete primary-key and foreign-key validation.

### Order Cardinality

The order-cardinality check returned the following results:

| Metric | Result |
|---|---:|
| Total distinct orders | 65,752 |
| Minimum item rows per order | 1 |
| Maximum item rows per order | 5 |
| Orders without item rows | 0 |
| Orders with repeated item IDs | 0 |

Every order represented in the staging dataset has at least one item row. These findings support the proposed order-to-order-item relationship, subject to validation against the complete normalized schema.

### Date Chronology

The initial date-profiling checks reported 65,752 distinct non-empty order-date values and 63,701 distinct non-empty shipping-date values.

The initial chronology query encountered a date-parsing error because values such as `4/15/2016 3:38` were not interpreted correctly under the PostgreSQL session's default date style.

After explicitly parsing the source date format, the corrected chronology query returned no rows indicating a shipping date earlier than the order date among the nonblank values successfully parsed.

This finding does not independently establish that every date is valid or that no date values are missing.

### Numerical Validity and Profit-Ratio Investigation

The initial numerical checks found no negative or zero order-item quantities, no negative sales values, and no negative product prices.

Further investigation of `Order Item Profit Ratio` produced the following results:

| Metric | Result |
|---|---:|
| Minimum ratio | -2.75 |
| Maximum ratio | 0.50 |
| Average ratio | Approximately 0.1206 |
| Negative-ratio rows | 33,784 |
| Zero-ratio rows | 1,177 |
| Positive-ratio rows | 145,558 |

The three groups account for all 180,519 rows.

A comparison with `Order Profit Per Order` found that the sign of the profit ratio matched the sign of order profit on every row included in the comparison. However, `Order Profit Per Order` is an order-level measure, while `Order Item Profit Ratio` is an item-level field. This sign agreement does not independently validate the item-level ratio calculation.

Additional inspection showed that individual orders can contain multiple distinct profit ratios. For example, order `10004` contains both negative and positive ratios. This supports treating the ratio as an item-level attribute rather than assuming it is constant across an order.

Negative ratios have not been classified as data errors because the authoritative calculation formula has not yet been independently verified. No source values have been modified or removed.

## Assumptions and Limitations

- The staging table, `staging.dataco_raw`, stores the source fields as text to preserve their original representation during profiling and validation.
- The dataset is treated as order-item-level data, with multiple rows potentially belonging to the same order.
- Repeated customer, product, category, and department identifiers are expected in the staging table. Uniqueness must be evaluated within each proposed entity's identifier domain.
- A blank query result means no rows matched that query's conditions; it does not prove complete data integrity.
- Negative profit ratios may represent legitimate loss-making transactions. Their precise business meaning and calculation have not been independently verified.
- The relationship between order-level and item-level financial measures requires further validation before defining aggregation rules.
- No source records have been deleted or modified as a result of these checks.

## Remaining Validation Work

Before creating the normalized tables, the following tasks remain:

1. Validate primary-key uniqueness and non-nullness for the proposed customer, order, order-item, product, category, and department entities.
2. Validate all foreign-key relationships against the proposed normalized schema.
3. Confirm the final product identifier mapping and the appropriate source column for the product foreign key.
4. Investigate additional numeric and date anomalies where justified.
5. Validate the business definitions and aggregation rules for sales, discounts, profit, and other financial measures.
6. Determine the appropriate PostgreSQL data types, primary keys, foreign keys, and other constraints.
7. Update the entity-relationship diagram if subsequent validation changes the proposed model.

The normalized tables should be implemented only after the remaining checks have been reviewed and the design decisions documented.