-- Purpose: Test key integrity, logical consistency, chronology,
-- and suspicious numeric values in the raw staging data.
-- All queries are read-only; no source rows are modified.
-- =========================================================

-- SECTION A: ENTITY IDENTIFIER COMPLETENESS AND UNIQUENESS
-- Check missing identifiers and candidate entity counts.
-- Counts alone do not establish primary-key suitability.

SELECT
    'Customer Id' AS identifier,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Customer Id"), '') IS NULL
    ) AS missing_rows,
    COUNT(DISTINCT NULLIF(BTRIM("Customer Id"), '')) AS distinct_ids
FROM staging.dataco_raw

UNION ALL

SELECT
    'Order Id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Order Id"), '') IS NULL
    ),
    COUNT(DISTINCT NULLIF(BTRIM("Order Id"), ''))
FROM staging.dataco_raw

UNION ALL

SELECT
    'Order Item Id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Order Item Id"), '') IS NULL
    ),
    COUNT(DISTINCT NULLIF(BTRIM("Order Item Id"), ''))
FROM staging.dataco_raw

UNION ALL

SELECT
    'Product Card Id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Product Card Id"), '') IS NULL
    ),
    COUNT(DISTINCT NULLIF(BTRIM("Product Card Id"), ''))
FROM staging.dataco_raw

UNION ALL

SELECT
    'Category Id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Category Id"), '') IS NULL
    ),
    COUNT(DISTINCT NULLIF(BTRIM("Category Id"), ''))
FROM staging.dataco_raw

UNION ALL

SELECT
    'Department Id',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Department Id"), '') IS NULL
    ),
    COUNT(DISTINCT NULLIF(BTRIM("Department Id"), ''))
FROM staging.dataco_raw
ORDER BY identifier;

-- Check duplicate non-empty Order Item Id values.
-- Expected result for a candidate row identifier: no rows returned.
SELECT
    BTRIM("Order Item Id") AS order_item_id,
    COUNT(*) AS row_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Item Id"), '') IS NOT NULL
GROUP BY BTRIM("Order Item Id")
HAVING COUNT(*) > 1
ORDER BY row_count DESC, order_item_id;

-- SECTION B: PRODUCT IDENTIFIER MAPPING AND REFERENCE INTEGRITY

-- Compare the two product ID fields on each order-item row.
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Order Item Cardprod Id"), '') IS NULL
    ) AS missing_order_item_product_ids,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Product Card Id"), '') IS NULL
    ) AS missing_product_ids,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Order Item Cardprod Id"), '') IS NOT NULL
          AND NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
          AND BTRIM("Order Item Cardprod Id") <> BTRIM("Product Card Id")
    ) AS mismatched_rows
FROM staging.dataco_raw;

-- Check whether every nonblank order-item product ID occurs among product IDs.
-- This tests the reference only; it does not validate all foreign keys.
WITH products AS (
    SELECT DISTINCT BTRIM("Product Card Id") AS product_id
    FROM staging.dataco_raw
    WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
),
order_item_products AS (
    SELECT DISTINCT BTRIM("Order Item Cardprod Id") AS product_id
    FROM staging.dataco_raw
    WHERE NULLIF(BTRIM("Order Item Cardprod Id"), '') IS NOT NULL
)
SELECT oi.product_id AS unmatched_product_id
FROM order_item_products AS oi
LEFT JOIN products AS p
    ON p.product_id = oi.product_id
WHERE p.product_id IS NULL
ORDER BY oi.product_id;

-- SECTION C: CUSTOMER AND ORDER-LEVEL CONSISTENCY

-- Customer Id and Order Customer Id should agree row by row.
SELECT COUNT(*) AS mismatched_customer_ids
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Customer Id"), '') IS DISTINCT FROM
      NULLIF(BTRIM("Order Customer Id"), '');

-- Check whether an order is associated with more than one customer.
SELECT
    "Order Id",
    COUNT(DISTINCT NULLIF(BTRIM("Customer Id"), '')) AS distinct_customer_ids,
    COUNT(*) AS row_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Id"), '') IS NOT NULL
GROUP BY "Order Id"
HAVING COUNT(DISTINCT NULLIF(BTRIM("Customer Id"), '')) > 1
ORDER BY distinct_customer_ids DESC, "Order Id";

-- Check whether order-level attributes vary across item rows in the same order.
-- COUNT(DISTINCT ...) ignores NULL; missing values are assessed separately.
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
WHERE NULLIF(BTRIM("Order Id"), '') IS NOT NULL
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

-- SECTION D: PRODUCT, CATEGORY, AND DEPARTMENT MAPPING

-- A product should not map to multiple names or prices in the source rows.
SELECT
    BTRIM("Product Card Id") AS product_id,
    COUNT(DISTINCT "Product Name") AS name_count,
    COUNT(DISTINCT "Product Price") AS price_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
GROUP BY BTRIM("Product Card Id")
HAVING COUNT(DISTINCT "Product Name") > 1
    OR COUNT(DISTINCT "Product Price") > 1
ORDER BY product_id;

-- A product should not map to multiple categories.
SELECT
    BTRIM("Product Card Id") AS product_id,
    COUNT(DISTINCT NULLIF(BTRIM("Product Category Id"), '')) AS category_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
GROUP BY BTRIM("Product Card Id")
HAVING COUNT(DISTINCT NULLIF(BTRIM("Product Category Id"), '')) > 1
ORDER BY product_id;

-- Count products that have at least one row with a missing category ID.
SELECT COUNT(*) AS products_with_missing_category
FROM (
    SELECT BTRIM("Product Card Id") AS product_id
    FROM staging.dataco_raw
    WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
    GROUP BY BTRIM("Product Card Id")
    HAVING COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Product Category Id"), '') IS NULL
    ) > 0
) AS product_category_check;

-- A Category Id should not map to multiple category names.
SELECT
    BTRIM("Category Id") AS category_id,
    COUNT(DISTINCT "Category Name") AS category_name_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Category Id"), '') IS NOT NULL
GROUP BY BTRIM("Category Id")
HAVING COUNT(DISTINCT "Category Name") > 1
ORDER BY category_id;

-- A Department Id should not map to multiple department names.
SELECT
    BTRIM("Department Id") AS department_id,
    COUNT(DISTINCT "Department Name") AS department_name_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Department Id"), '') IS NOT NULL
GROUP BY BTRIM("Department Id")
HAVING COUNT(DISTINCT "Department Name") > 1
ORDER BY department_id;

-- A product should not map to multiple departments.
SELECT
    BTRIM("Product Card Id") AS product_id,
    COUNT(DISTINCT NULLIF(BTRIM("Department Id"), '')) AS department_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
GROUP BY BTRIM("Product Card Id")
HAVING COUNT(DISTINCT NULLIF(BTRIM("Department Id"), '')) > 1
ORDER BY product_id;

-- SECTION E: DELIVERY STATUS / LATE-DELIVERY FLAG
-- Inspect the cross-tab. Interpret combinations against documented source
-- definitions; do not infer that every risk=1 row must have the same status
-- without confirming the dataset's business definition.
SELECT
    "Delivery Status",
    "Late_delivery_risk",
    COUNT(*) AS row_count
FROM staging.dataco_raw
GROUP BY "Delivery Status", "Late_delivery_risk"
ORDER BY "Delivery Status", "Late_delivery_risk";

-- SECTION F: ORDER CARDINALITY AND ITEM IDENTIFIERS
-- Because this is an order-item table, orders present here necessarily have
-- at least one row. This query measures observed rows/items per represented order.
WITH order_item_counts AS (
    SELECT
        BTRIM("Order Id") AS order_id,
        COUNT(*) AS item_rows,
        COUNT(DISTINCT NULLIF(BTRIM("Order Item Id"), '')) AS distinct_nonblank_item_ids
    FROM staging.dataco_raw
    WHERE NULLIF(BTRIM("Order Id"), '') IS NOT NULL
    GROUP BY BTRIM("Order Id")
)
SELECT
    COUNT(*) AS represented_orders,
    MIN(item_rows) AS minimum_item_rows,
    MAX(item_rows) AS maximum_item_rows,
    COUNT(*) FILTER (
        WHERE item_rows <> distinct_nonblank_item_ids
    ) AS orders_with_missing_or_repeated_item_ids
FROM order_item_counts;

-- SECTION G: NUMERICAL VALIDITY
-- File 03 checks numeric text syntax. These checks look for suspicious values.
-- Guard casts with a numeric-format check so malformed text will not abort them.
WITH numeric_fields AS (
    SELECT
        "Order Item Quantity" AS quantity_text,
        "Sales" AS sales_text,
        "Order Item Product Price" AS item_price_text,
        "Order Item Profit Ratio" AS profit_ratio_text
    FROM staging.dataco_raw
),
parsed AS (
    SELECT
        CASE WHEN BTRIM(quantity_text) ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$'
             THEN BTRIM(quantity_text)::NUMERIC END AS quantity,
        CASE WHEN BTRIM(sales_text) ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$'
             THEN BTRIM(sales_text)::NUMERIC END AS sales,
        CASE WHEN BTRIM(item_price_text) ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$'
             THEN BTRIM(item_price_text)::NUMERIC END AS item_price,
        CASE WHEN BTRIM(profit_ratio_text) ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$'
             THEN BTRIM(profit_ratio_text)::NUMERIC END AS profit_ratio
    FROM numeric_fields
)
SELECT
    COUNT(*) FILTER (WHERE quantity < 0) AS negative_quantities,
    COUNT(*) FILTER (WHERE quantity = 0) AS zero_quantities,
    COUNT(*) FILTER (WHERE sales < 0) AS negative_sales,
    COUNT(*) FILTER (WHERE item_price < 0) AS negative_item_prices,
    COUNT(*) FILTER (WHERE profit_ratio < 0) AS negative_profit_ratios,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS unparsed_or_missing_quantities,
    COUNT(*) FILTER (WHERE sales IS NULL) AS unparsed_or_missing_sales,
    COUNT(*) FILTER (WHERE item_price IS NULL) AS unparsed_or_missing_item_prices,
    COUNT(*) FILTER (WHERE profit_ratio IS NULL) AS unparsed_or_missing_profit_ratios
FROM parsed;

-- SECTION H: DATE CHRONOLOGY
-- This checks for shipping timestamps before order timestamps among nonblank
-- values. Run after reviewing the date-format results in file 03.
WITH parsed_dates AS (
    SELECT
        "Order Id" AS order_id,
        "Order Item Id" AS order_item_id,
        TO_TIMESTAMP(
            NULLIF(BTRIM("order date (DateOrders)"), ''),
            'MM/DD/YYYY HH24:MI'
        ) AS order_datetime,
        TO_TIMESTAMP(
            NULLIF(BTRIM("shipping date (DateOrders)"), ''),
            'MM/DD/YYYY HH24:MI'
        ) AS shipping_datetime
    FROM staging.dataco_raw
)
SELECT
    order_id,
    order_item_id,
    order_datetime,
    shipping_datetime
FROM parsed_dates
WHERE order_datetime IS NOT NULL
  AND shipping_datetime IS NOT NULL
  AND shipping_datetime < order_datetime
ORDER BY order_datetime
LIMIT 100;

-- SECTION I: PROFIT-RATIO / ORDER-PROFIT SIGN COMPARISON
-- Order Profit Per Order is an order-level measure repeated on item rows.
-- This comparison is diagnostic, not independent mathematical validation of
-- the item-level profit ratio.
WITH parsed AS (
    SELECT
        CASE
            WHEN "Order Item Profit Ratio" ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$'
                THEN "Order Item Profit Ratio"::NUMERIC
        END AS profit_ratio,
        CASE
            WHEN "Order Profit Per Order" ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$'
                THEN "Order Profit Per Order"::NUMERIC
        END AS order_profit
    FROM staging.dataco_raw
)
SELECT
    CASE
        WHEN profit_ratio < 0 THEN 'Negative ratio'
        WHEN profit_ratio = 0 THEN 'Zero ratio'
        WHEN profit_ratio > 0 THEN 'Positive ratio'
        ELSE 'Missing or unparsed ratio'
    END AS ratio_group,
    COUNT(*) AS row_count,
    COUNT(*) FILTER (WHERE order_profit < 0) AS negative_order_profit_rows,
    COUNT(*) FILTER (WHERE order_profit = 0) AS zero_order_profit_rows,
    COUNT(*) FILTER (WHERE order_profit > 0) AS positive_order_profit_rows,
    MIN(order_profit) AS minimum_order_profit,
    MAX(order_profit) AS maximum_order_profit
FROM parsed
WHERE profit_ratio IS NOT NULL
  AND order_profit IS NOT NULL
GROUP BY ratio_group
ORDER BY ratio_group;
