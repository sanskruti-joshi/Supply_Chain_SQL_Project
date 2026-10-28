
## Initial Data Inspection

The initial sample suggests that the dataset contains order-item-level records, with order, customer, product, sales, and shipping attributes represented in the same table.

The following points require validation before analysis:

- Whether `Order Item Id` uniquely identifies each record.
- Whether multiple order items can share the same `Order Id`.
- Whether `Product Category Id` is missing for some records or whether the blank value in the sample is a formatting issue.
- Whether shipping dates are missing, invalid, or merely displayed incorrectly.
- Whether `Delivery Status` agrees with `Late_delivery_risk`.
- Whether sales and profit measures should be aggregated at the order-item or order level.

No conclusions about data quality or business performance have been established from this sample alone.


## Initial Profiling Findings

The source CSV contains 180,519 data rows and 53 columns. 
Initial profiling indicates:

- 65,752 distinct order IDs.
- 180,519 distinct order-item IDs, matching the total row count.
- 20,652 distinct customer IDs.
- 118 distinct product IDs.
- No duplicate non-empty order-item IDs were returned by the initial duplicate check.
- The inspected important fields contained no SQL NULLs or empty/whitespace values.
- The inspected numerical fields contained no values that failed the expected numeric syntax checks.
- The inspected date fields matched the expected text format.
- The count of rows classified as `Late delivery` matched the count with `Late_delivery_risk = 1`.

These are preliminary findings. Additional checks are required to validate identifier uniqueness, relationships, delivery-status consistency, category mappings, and business-level metric definitions.

The staging table currently stores source fields as text. Final data types, constraints, and the normalized schema will be determined after further validation.
