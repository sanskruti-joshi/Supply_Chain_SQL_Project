# Assumptions and Limitations

## Working Assumptions

- `staging.dataco_raw` represents the source CSV at order-item grain: multiple rows may belong to one order.
- The raw staging table retains source values as text to preserve their original representation during profiling.
- Repeated customer, product, category, and department identifiers in staging are expected; uniqueness is assessed within each proposed entity rather than across the denormalized rows.
- A query returning no matching rows only supports the condition tested. It does not establish complete integrity or correctness.
- The source glossary is descriptive metadata, not independent proof of a field's business meaning.

## Limitations

- The dataset's coverage period, completeness, and representativeness have not been independently established.
- Available fields may show an association with delivery outcomes but do not explain the causes of delays.
- Supplier identifiers and inventory/replenishment history are not established in the current dataset; supplier-performance and inventory-risk conclusions are therefore out of scope without additional data.
- Customer-related fields exist in the source. Keep raw data and query results private; do not publish customer values or commit derived exports without an appropriate review.
- `Order Profit Per Order` is an order-level measure repeated on item rows. Summing it directly across staging rows would risk double counting.
- The exact business definitions and aggregation rules for sales, discounts, profit, and delivery denominators remain subject to validation.

## Validation Still Required

- Confirm candidate primary-key uniqueness and non-nullness for each entity in the proposed model.
- Validate all foreign-key relationships after the normalized schema is designed.
- Finalize the order-item product identifier mapping and appropriate source columns.
- Choose defensible aggregation rules for financial and delivery measures.
- Finalize PostgreSQL data types and constraints before implementing normalized tables.

Reported profiling and consistency-check results are collected in [findings_report.md](./findings_report.md), rather than repeated here or in the ER diagram.
