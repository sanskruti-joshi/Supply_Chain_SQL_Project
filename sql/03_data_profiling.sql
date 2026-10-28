-- These checks preserve the raw staging table.

-- 1. Total imported rows.
SELECT COUNT(*) AS imported_row_count
FROM staging.dataco_raw;

-- 2. The source header was verified to contain 53 fields. Compare that
-- contract with the actual staging-table definition.
SELECT
    53 AS expected_column_count,
    COUNT(*) AS actual_column_count,
    COUNT(*) = 53 AS column_count_matches
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'dataco_raw';

-- 3. Null and empty/whitespace-only values in identifiers and core dimensions.
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
        ('Product Card Id', r."Product Card Id"),
        ('Delivery Status', r."Delivery Status"),
        ('Order Status', r."Order Status"),
        ('Shipping Mode', r."Shipping Mode"),
        ('order date (DateOrders)', r."order date (DateOrders)"),
        ('shipping date (DateOrders)', r."shipping date (DateOrders)"),
        ('Category Id', r."Category Id")
) AS fields(field_name, field_value)
GROUP BY field_name
ORDER BY field_name;

-- 4. Distinct identifier counts. Blank identifiers are excluded; these counts
-- do not assert that any identifier is a primary key.
SELECT
    COUNT(DISTINCT "Order Id") FILTER (
        WHERE NULLIF(BTRIM("Order Id"), '') IS NOT NULL
    ) AS distinct_order_ids,
    COUNT(DISTINCT "Order Item Id") FILTER (
        WHERE NULLIF(BTRIM("Order Item Id"), '') IS NOT NULL
    ) AS distinct_order_item_ids,
    COUNT(DISTINCT "Customer Id") FILTER (
        WHERE NULLIF(BTRIM("Customer Id"), '') IS NOT NULL
    ) AS distinct_customer_ids,
    COUNT(DISTINCT "Product Card Id") FILTER (
        WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
    ) AS distinct_product_card_ids
FROM staging.dataco_raw;

-- 5. Duplicate non-empty Order Item Id values; no duplicates are removed.
SELECT
    "Order Item Id",
    COUNT(*) AS row_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Item Id"), '') IS NOT NULL
GROUP BY "Order Item Id"
HAVING COUNT(*) > 1
ORDER BY row_count DESC, "Order Item Id";

-- 6a. Date-field summary. The expected source shape is M/D/YYYY H:MM.
-- This checks shape only, not calendar validity (for example, February 30).
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

-- 6b. Inspect up to 40 distinct raw date values and their frequencies.
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

-- 7. Conservative text-format checks for fields intended to be numeric.
-- Blank values are counted separately above; no casts are attempted here.
-- These checks validate syntax only, not a future target type's range/precision.
-- Postal codes are intentionally left out because they are identifiers, not
-- numeric measures, and should remain text to preserve formatting.
WITH numeric_values AS (
    SELECT
        field_name,
        raw_value,
        value_kind
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


-- Checks to validate the dataset's logical relationships.

-- Check 1: Verify delivery status against risk.
SELECT
    "Delivery Status",
    "Late_delivery_risk",
    COUNT(*) AS row_count
FROM staging.dataco_raw
group by "Delivery Status", "Late_delivery_risk"
ORDER BY "Delivery Status", "Late_delivery_risk";

-- Check 2: Check whether orders have consistent customer IDs.
SELECT
    "Order Id",
    COUNT(DISTINCT "Customer Id") AS distinct_customer_ids,
    COUNT(*) AS row_count
FROM staging.dataco_raw
GROUP BY "Order Id"
having COUNT(DISTINCT "Customer Id") > 1
ORDER BY distinct_customer_ids DESC, "Order Id";

-- Check 3: Compare product and category identifiers.
SELECT
    "Product Card Id",
    COUNT(DISTINCT "Product Category Id") AS distinct_category_ids
from staging.dataco_raw
where NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
group by "Product Card Id"
having COUNT(DISTINCT "Product Category Id") > 1
order by distinct_category_ids DESC, "Product Card Id";

-- Check 4: Compare customer identifiers
SELECT 
    COUNT(*) AS mismatched_customer_ids
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Customer Id"), '') IS DISTINCT FROM
      NULLIF(BTRIM("Order Customer Id"), '');

-- Check 5: Check missing identifiers.
SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Order Item Id"), '') IS NULL
    ) AS missing_order_item_ids,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Order Id"), '') IS NULL
    ) AS missing_order_ids,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Customer Id"), '') IS NULL
    ) AS missing_customer_ids,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Product Card Id"), '') IS NULL
    ) AS missing_product_ids,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Product Category Id"), '') IS NULL
    ) AS missing_product_category_ids
FROM staging.dataco_raw;

-- Check 6: Check whether each product has one category.
SELECT
    COUNT(*) AS products_with_missing_category
FROM (
    SELECT
        "Product Card Id"
    FROM staging.dataco_raw
    WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
    GROUP BY "Product Card Id"
    HAVING COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Product Category Id"), '') IS NULL
    ) > 0
) AS product_category_check;


-- Check 7: Order-level consistency checks. Identify attributes that vary within an order.
SELECT
    "Order Id",
    COUNT(DISTINCT "Order Customer Id") AS customer_count,
    COUNT(DISTINCT "order date (DateOrders)") AS order_date_count,
    COUNT(DISTINCT "Order Status") AS order_status_count,
    COUNT(DISTINCT "Shipping Mode") AS shipping_mode_count,
    COUNT(DISTINCT "Market") AS market_count,
    COUNT(DISTINCT "Order City") AS city_count,
    COUNT(DISTINCT "Order Country") AS country_count,
    COUNT(DISTINCT "Order Region") AS region_count,
    COUNT(DISTINCT "Order State") AS state_count
FROM staging.dataco_raw
GROUP BY "Order Id"
HAVING
       COUNT(DISTINCT "Order Customer Id") > 1
    OR COUNT(DISTINCT "order date (DateOrders)") > 1
    OR COUNT(DISTINCT "Order Status") > 1
    OR COUNT(DISTINCT "Shipping Mode") > 1
    OR COUNT(DISTINCT "Market") > 1
    OR COUNT(DISTINCT "Order City") > 1
    OR COUNT(DISTINCT "Order Country") > 1
    OR COUNT(DISTINCT "Order Region") > 1
    OR COUNT(DISTINCT "Order State") > 1
ORDER BY "Order Id";

-- Check 8: Check product attributes. Whether a Product ID maps to multiple names or prices.
SELECT
    "Product Card Id",
    COUNT(DISTINCT "Product Name") AS name_count,
    COUNT(DISTINCT "Product Price") AS price_count
FROM staging.dataco_raw
GROUP BY "Product Card Id"
HAVING
       COUNT(DISTINCT "Product Name") > 1
    OR COUNT(DISTINCT "Product Price") > 1
ORDER BY "Product Card Id";

-- Check 9: Check category names. Whether a category ID maps to multiple category names
SELECT
    "Category Id",
    COUNT(DISTINCT "Category Name") AS category_name_count
FROM staging.dataco_raw
GROUP BY "Category Id"
HAVING COUNT(DISTINCT "Category Name") > 1
ORDER BY "Category Id";

-- Check 10: Check product-to-department consistency. Whether products appear in multiple departments
SELECT
    "Product Card Id",
    COUNT(DISTINCT "Department Id") AS department_count
FROM staging.dataco_raw
GROUP BY "Product Card Id"
HAVING COUNT(DISTINCT "Department Id") > 1
ORDER BY "Product Card Id";


-- Check 11: Category and Department Identifier Validation

-- Check category IDs against category names
SELECT
    "Category Id",
    COUNT(DISTINCT "Category Name") AS category_name_count
FROM staging.dataco_raw
GROUP BY "Category Id"
HAVING COUNT(DISTINCT "Category Name") > 1
ORDER BY "Category Id";


-- Check department IDs against department names
SELECT
    "Department Id",
    COUNT(DISTINCT "Department Name") AS department_name_count
FROM staging.dataco_raw
GROUP BY "Department Id"
HAVING COUNT(DISTINCT "Department Name") > 1
ORDER BY "Department Id";


-- Check product IDs against product category IDs
SELECT
    "Product Card Id",
    COUNT(DISTINCT "Product Category Id") AS category_count
FROM staging.dataco_raw
GROUP BY "Product Card Id"
HAVING COUNT(DISTINCT "Product Category Id") > 1
ORDER BY "Product Card Id";
