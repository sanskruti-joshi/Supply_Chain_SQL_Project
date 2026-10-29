-- Purpose: Describe the raw DataCo dataset before validation
-- or transformation. All queries are read-only.
-- =========================================================

-- 1. Overall dataset size.
SELECT COUNT(*) AS imported_row_count
FROM staging.dataco_raw;

-- 2. Compare the expected source width with the staging table.
SELECT
    53 AS expected_column_count,
    COUNT(*) AS actual_column_count,
    COUNT(*) = 53 AS column_count_matches
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'dataco_raw';

-- 3. Completeness profile for key identifiers and core dimensions.
-- This is a focused profile, not an all-53-column completeness report.
SELECT
    field_name,
    COUNT(*) FILTER (WHERE field_value IS NULL) AS null_count,
    COUNT(*) FILTER (
        WHERE field_value IS NOT NULL AND BTRIM(field_value) = ''
    ) AS empty_or_whitespace_count
FROM staging.dataco_raw AS r
CROSS JOIN LATERAL (
    VALUES
        ('Order Id', r."Order Id"),
        ('Order Item Id', r."Order Item Id"),
        ('Customer Id', r."Customer Id"),
        ('Order Customer Id', r."Order Customer Id"),
        ('Product Card Id', r."Product Card Id"),
        ('Order Item Cardprod Id', r."Order Item Cardprod Id"),
        ('Category Id', r."Category Id"),
        ('Product Category Id', r."Product Category Id"),
        ('Department Id', r."Department Id"),
        ('Delivery Status', r."Delivery Status"),
        ('Order Status', r."Order Status"),
        ('Shipping Mode', r."Shipping Mode"),
        ('order date (DateOrders)', r."order date (DateOrders)"),
        ('shipping date (DateOrders)', r."shipping date (DateOrders)")
) AS fields(field_name, field_value)
GROUP BY field_name
ORDER BY field_name;

-- 4. Distinct identifier counts. These counts do not by themselves prove
-- uniqueness or suitability as primary keys.
SELECT
    COUNT(DISTINCT NULLIF(BTRIM("Order Id"), '')) AS distinct_order_ids,
    COUNT(DISTINCT NULLIF(BTRIM("Order Item Id"), '')) AS distinct_order_item_ids,
    COUNT(DISTINCT NULLIF(BTRIM("Customer Id"), '')) AS distinct_customer_ids,
    COUNT(DISTINCT NULLIF(BTRIM("Product Card Id"), '')) AS distinct_product_card_ids,
    COUNT(DISTINCT NULLIF(BTRIM("Category Id"), '')) AS distinct_category_ids,
    COUNT(DISTINCT NULLIF(BTRIM("Department Id"), '')) AS distinct_department_ids
FROM staging.dataco_raw;

-- 5. Date-field summary. The expected source shape is M/D/YYYY H:MM.
-- This checks text shape, not full calendar validity.
WITH date_fields AS (
    SELECT 'order date (DateOrders)' AS field_name,
           "order date (DateOrders)" AS raw_value
    FROM staging.dataco_raw
    UNION ALL
    SELECT 'shipping date (DateOrders)',
           "shipping date (DateOrders)"
    FROM staging.dataco_raw
)
SELECT
    field_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT raw_value) FILTER (
        WHERE NULLIF(BTRIM(raw_value), '') IS NOT NULL
    ) AS distinct_nonempty_values,
    COUNT(*) FILTER (
        WHERE raw_value IS NULL OR BTRIM(raw_value) = ''
    ) AS null_or_empty_count,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(raw_value), '') IS NOT NULL
          AND BTRIM(raw_value) !~
              '^(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/[0-9]{4} ([01]?[0-9]|2[0-3]):[0-5][0-9]$'
    ) AS nonmatching_format_count,
    MIN(raw_value) FILTER (
        WHERE NULLIF(BTRIM(raw_value), '') IS NOT NULL
    ) AS minimum_raw_value,
    MAX(raw_value) FILTER (
        WHERE NULLIF(BTRIM(raw_value), '') IS NOT NULL
    ) AS maximum_raw_value
FROM date_fields
GROUP BY field_name
ORDER BY field_name;

-- 6. Inspect a small sample of distinct date strings and their frequencies.
WITH date_fields AS (
    SELECT 'order date (DateOrders)' AS field_name,
        "order date (DateOrders)" AS raw_value
    FROM staging.dataco_raw
    UNION ALL
    SELECT 'shipping date (DateOrders)',
           "shipping date (DateOrders)"
    FROM staging.dataco_raw
)
SELECT field_name, raw_value, COUNT(*) AS row_count
FROM date_fields
WHERE NULLIF(BTRIM(raw_value), '') IS NOT NULL
GROUP BY field_name, raw_value
ORDER BY field_name, raw_value
LIMIT 40;

-- 7. Check text syntax for fields expected to be numeric.
-- This validates syntax only, not semantic ranges or target-type precision.
-- Postal codes are omitted because they are identifiers and should remain text.
WITH numeric_values AS (
    SELECT field_name, raw_value, value_kind
    FROM staging.dataco_raw AS r
    CROSS JOIN LATERAL (
        VALUES
            ('Days for shipping (real)', r."Days for shipping (real)", 'integer'),
            ('Days for shipment (scheduled)', r."Days for shipment (scheduled)", 'integer'),
            ('Benefit per order', r."Benefit per order", 'decimal'),
            ('Sales per customer', r."Sales per customer", 'decimal'),
            ('Late_delivery_risk', r."Late_delivery_risk", 'integer'),
            ('Category Id', r."Category Id", 'integer'),
            ('Customer Id', r."Customer Id", 'integer'),
            ('Department Id', r."Department Id", 'integer'),
            ('Latitude', r."Latitude", 'decimal'),
            ('Longitude', r."Longitude", 'decimal'),
            ('Order Customer Id', r."Order Customer Id", 'integer'),
            ('Order Id', r."Order Id", 'integer'),
            ('Order Item Cardprod Id', r."Order Item Cardprod Id", 'integer'),
            ('Order Item Discount', r."Order Item Discount", 'decimal'),
            ('Order Item Discount Rate', r."Order Item Discount Rate", 'decimal'),
            ('Order Item Id', r."Order Item Id", 'integer'),
            ('Order Item Product Price', r."Order Item Product Price", 'decimal'),
            ('Order Item Profit Ratio', r."Order Item Profit Ratio", 'decimal'),
            ('Order Item Quantity', r."Order Item Quantity", 'integer'),
            ('Sales', r."Sales", 'decimal'),
            ('Order Item Total', r."Order Item Total", 'decimal'),
            ('Order Profit Per Order', r."Order Profit Per Order", 'decimal'),
            ('Product Card Id', r."Product Card Id", 'integer'),
            ('Product Category Id', r."Product Category Id", 'integer'),
            ('Product Price', r."Product Price", 'decimal'),
            ('Product Status', r."Product Status", 'integer')
    ) AS fields(field_name, raw_value, value_kind)
),
conversion_checks AS (
    SELECT
        field_name,
        CASE
            WHEN NULLIF(BTRIM(raw_value), '') IS NULL THEN NULL
            WHEN value_kind = 'integer'
                THEN BTRIM(raw_value) ~ '^[+-]?[0-9]+$'
            ELSE BTRIM(raw_value) ~
                '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$'
        END AS conversion_format_ok
    FROM numeric_values
)
SELECT
    field_name,
    COUNT(*) FILTER (
        WHERE conversion_format_ok IS NOT NULL
    ) AS nonempty_value_count,
    COUNT(*) FILTER (
        WHERE conversion_format_ok IS FALSE
    ) AS invalid_numeric_format_count
FROM conversion_checks
GROUP BY field_name
ORDER BY field_name;

-- 8. Enumerate observed values and frequencies for key categorical fields.
-- Useful for discovering unexpected labels; consistency rules are in file 04.
SELECT
    field_name,
    field_value,
    COUNT(*) AS row_count
FROM staging.dataco_raw AS r
CROSS JOIN LATERAL (
    VALUES
        ('Delivery Status', r."Delivery Status"),
        ('Order Status', r."Order Status"),
        ('Shipping Mode', r."Shipping Mode"),
        ('Late_delivery_risk', r."Late_delivery_risk")
) AS fields(field_name, field_value)
WHERE NULLIF(BTRIM(field_value), '') IS NOT NULL
GROUP BY field_name, field_value
ORDER BY field_name, field_value;

-- 9. Profile the distribution of Order Item Profit Ratio.
-- Negative values are not automatically errors; interpret them using the
-- dataset's business definition before making any cleaning decision.
SELECT
    MIN("Order Item Profit Ratio"::NUMERIC) AS minimum_profit_ratio,
    MAX("Order Item Profit Ratio"::NUMERIC) AS maximum_profit_ratio,
    AVG("Order Item Profit Ratio"::NUMERIC) AS average_profit_ratio,
    COUNT(*) FILTER (
        WHERE "Order Item Profit Ratio"::NUMERIC < 0
    ) AS negative_ratio_rows,
    COUNT(*) FILTER (
        WHERE "Order Item Profit Ratio"::NUMERIC = 0
    ) AS zero_ratio_rows,
    COUNT(*) FILTER (
        WHERE "Order Item Profit Ratio"::NUMERIC > 0
    ) AS positive_ratio_rows
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Item Profit Ratio"), '') IS NOT NULL;

-- 10. Inspect a sample of records with negative profit ratios.
SELECT
    "Order Id",
    "Order Item Id",
    "Product Name",
    "Sales",
    "Order Item Profit Ratio",
    "Order Item Total"
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Item Profit Ratio"), '') IS NOT NULL
  AND "Order Item Profit Ratio"::NUMERIC < 0
ORDER BY "Order Item Profit Ratio"::NUMERIC
LIMIT 20;

-- 11. Inspect the distribution of distinct profit-ratio values.
SELECT
    "Order Item Profit Ratio"::NUMERIC AS profit_ratio,
    COUNT(*) AS row_count,
    MIN("Sales"::NUMERIC) AS minimum_sales,
    MAX("Sales"::NUMERIC) AS maximum_sales
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Item Profit Ratio"), '') IS NOT NULL
  AND NULLIF(BTRIM("Sales"), '') IS NOT NULL
GROUP BY "Order Item Profit Ratio"::NUMERIC
ORDER BY profit_ratio;

-- 12. Inspect records with the largest absolute profit ratios.
SELECT
    "Order Id",
    "Order Item Id",
    "Product Name",
    "Order Item Profit Ratio",
    "Order Profit Per Order",
    "Sales",
    "Order Item Total"
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Item Profit Ratio"), '') IS NOT NULL
ORDER BY ABS("Order Item Profit Ratio"::NUMERIC) DESC
LIMIT 20;

-- 13. Investigate whether profit ratio varies between items in an order.
-- This is descriptive exploration, not an assumption that the ratio must match.
SELECT
    "Order Id",
    COUNT(*) AS item_rows,
    COUNT(DISTINCT "Order Item Profit Ratio") AS distinct_ratios,
    MIN("Order Item Profit Ratio"::NUMERIC) AS min_ratio,
    MAX("Order Item Profit Ratio"::NUMERIC) AS max_ratio
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Id"), '') IS NOT NULL
  AND NULLIF(BTRIM("Order Item Profit Ratio"), '') IS NOT NULL
GROUP BY "Order Id"
HAVING COUNT(DISTINCT "Order Item Profit Ratio") > 1
ORDER BY "Order Id"
LIMIT 100;