-- Purpose: Validate key integrity, row-grain assumptions, and data-quality issues
-- relevant to the proposed normalized relational model. All queries are read-only.
-- =========================================================

-- SECTION A: CANDIDATE IDENTIFIERS AND COMPLETENESS
-- Counts alone do not establish primary-key suitability; they highlight rows that
-- may be missing keys before a normalized design is finalized.
SELECT
    'Customer Id' AS identifier,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Customer Id"), '') IS NULL) AS missing_rows,
    COUNT(DISTINCT NULLIF(BTRIM("Customer Id"), '')) AS distinct_ids
FROM staging.dataco_raw
UNION ALL
SELECT
    'Order Id',
    COUNT(*),
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Order Id"), '') IS NULL),
    COUNT(DISTINCT NULLIF(BTRIM("Order Id"), ''))
FROM staging.dataco_raw
UNION ALL
SELECT
    'Order Item Id',
    COUNT(*),
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Order Item Id"), '') IS NULL),
    COUNT(DISTINCT NULLIF(BTRIM("Order Item Id"), ''))
FROM staging.dataco_raw
UNION ALL
SELECT
    'Product Card Id',
    COUNT(*),
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Product Card Id"), '') IS NULL),
    COUNT(DISTINCT NULLIF(BTRIM("Product Card Id"), ''))
FROM staging.dataco_raw
UNION ALL
SELECT
    'Category Id',
    COUNT(*),
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Category Id"), '') IS NULL),
    COUNT(DISTINCT NULLIF(BTRIM("Category Id"), ''))
FROM staging.dataco_raw
UNION ALL
SELECT
    'Department Id',
    COUNT(*),
    COUNT(*) FILTER (WHERE NULLIF(BTRIM("Department Id"), '') IS NULL),
    COUNT(DISTINCT NULLIF(BTRIM("Department Id"), ''))
FROM staging.dataco_raw
ORDER BY identifier;

-- Check for duplicate non-empty Order Item Id values.
SELECT
    BTRIM("Order Item Id") AS order_item_id,
    COUNT(*) AS row_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Item Id"), '') IS NOT NULL
GROUP BY BTRIM("Order Item Id")
HAVING COUNT(*) > 1
ORDER BY row_count DESC, order_item_id;

-- SECTION B: CUSTOMER-ORDER AND CUSTOMER-ATTRIBUTE INTEGRITY
-- Customer Id and Order Customer Id should align row by row.
SELECT COUNT(*) AS mismatched_customer_id_rows
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Customer Id"), '') IS DISTINCT FROM NULLIF(BTRIM("Order Customer Id"), '');

-- Detect orders associated with more than one customer.
SELECT
    "Order Id",
    COUNT(DISTINCT NULLIF(BTRIM("Customer Id"), '')) AS distinct_customer_ids,
    COUNT(*) AS row_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Order Id"), '') IS NOT NULL
GROUP BY "Order Id"
HAVING COUNT(DISTINCT NULLIF(BTRIM("Customer Id"), '')) > 1
ORDER BY distinct_customer_ids DESC, "Order Id";

-- Customer attribute consistency: number of customers with multiple non-empty values
-- across the customer fields below.
WITH customer_fields AS (
    SELECT 'Customer Segment' AS field_name, "Customer Id" AS customer_id, "Customer Segment" AS field_value FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Fname', "Customer Id", "Customer Fname" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Lname', "Customer Id", "Customer Lname" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Email', "Customer Id", "Customer Email" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer City', "Customer Id", "Customer City" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Country', "Customer Id", "Customer Country" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer State', "Customer Id", "Customer State" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Street', "Customer Id", "Customer Street" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Zipcode', "Customer Id", "Customer Zipcode" FROM staging.dataco_raw
),
clean_fields AS (
    SELECT
        field_name,
        customer_id,
        NULLIF(BTRIM(field_value), '') AS field_value
    FROM customer_fields
    WHERE NULLIF(BTRIM(field_value), '') IS NOT NULL
),
customer_value_counts AS (
    SELECT
        field_name,
        customer_id,
        COUNT(DISTINCT field_value) AS distinct_nonempty_values
    FROM clean_fields
    GROUP BY field_name, customer_id
)
SELECT
    field_name,
    COUNT(*) AS affected_customer_count
FROM customer_value_counts
WHERE distinct_nonempty_values > 1
GROUP BY field_name
ORDER BY field_name;

-- Limited sample of customer IDs with inconsistent values for investigation.
WITH customer_fields AS (
    SELECT 'Customer Segment' AS field_name, "Customer Id" AS customer_id, "Customer Segment" AS field_value FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Fname', "Customer Id", "Customer Fname" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Lname', "Customer Id", "Customer Lname" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Email', "Customer Id", "Customer Email" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer City', "Customer Id", "Customer City" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Country', "Customer Id", "Customer Country" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer State', "Customer Id", "Customer State" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Street', "Customer Id", "Customer Street" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Customer Zipcode', "Customer Id", "Customer Zipcode" FROM staging.dataco_raw
),
clean_fields AS (
    SELECT field_name, customer_id, NULLIF(BTRIM(field_value), '') AS field_value
    FROM customer_fields
    WHERE NULLIF(BTRIM(field_value), '') IS NOT NULL
),
customer_value_counts AS (
    SELECT field_name, customer_id, COUNT(DISTINCT field_value) AS distinct_nonempty_values
    FROM clean_fields
    GROUP BY field_name, customer_id
)
SELECT field_name, customer_id, distinct_nonempty_values
FROM customer_value_counts
WHERE distinct_nonempty_values > 1
ORDER BY field_name, customer_id
LIMIT 50;

-- SECTION C: CATEGORY-IDENTIFIER EQUIVALENCE
-- Check whether Category Id and Product Category Id match across rows.
SELECT
    COUNT(*) AS total_rows_checked,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM("Category Id"), '') IS DISTINCT FROM NULLIF(BTRIM("Product Category Id"), '')
    ) AS mismatched_rows
FROM staging.dataco_raw;

-- Sample mismatched category references for review.
SELECT
    "Order Id",
    "Order Item Id",
    "Product Card Id",
    "Category Id",
    "Product Category Id"
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Category Id"), '') IS DISTINCT FROM NULLIF(BTRIM("Product Category Id"), '')
ORDER BY "Order Id", "Order Item Id"
LIMIT 50;

-- SECTION D: ORDER-LEVEL GRAIN VALIDATION
-- Check whether Type and shipping/delivery attributes vary within an order.
WITH order_field_values AS (
    SELECT 'Type' AS field_name, "Order Id" AS order_id, "Type" AS field_value FROM staging.dataco_raw
    UNION ALL
    SELECT 'Delivery Status', "Order Id", "Delivery Status" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Late_delivery_risk', "Order Id", "Late_delivery_risk" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Days for shipping (real)', "Order Id", "Days for shipping (real)" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Days for shipment (scheduled)', "Order Id", "Days for shipment (scheduled)" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Shipping date (DateOrders)', "Order Id", "shipping date (DateOrders)" FROM staging.dataco_raw
),
clean_fields AS (
    SELECT field_name, order_id, NULLIF(BTRIM(field_value), '') AS field_value
    FROM order_field_values
    WHERE NULLIF(BTRIM(field_value), '') IS NOT NULL
),
order_value_counts AS (
    SELECT field_name, order_id, COUNT(DISTINCT field_value) AS distinct_nonempty_values
    FROM clean_fields
    GROUP BY field_name, order_id
)
SELECT
    field_name,
    COUNT(*) AS affected_orders
FROM order_value_counts
WHERE distinct_nonempty_values > 1
GROUP BY field_name
ORDER BY field_name;

-- Sample of affected orders for investigation.
WITH order_field_values AS (
    SELECT 'Type' AS field_name, "Order Id" AS order_id, "Type" AS field_value FROM staging.dataco_raw
    UNION ALL
    SELECT 'Delivery Status', "Order Id", "Delivery Status" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Late_delivery_risk', "Order Id", "Late_delivery_risk" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Days for shipping (real)', "Order Id", "Days for shipping (real)" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Days for shipment (scheduled)', "Order Id", "Days for shipment (scheduled)" FROM staging.dataco_raw
    UNION ALL
    SELECT 'Shipping date (DateOrders)', "Order Id", "shipping date (DateOrders)" FROM staging.dataco_raw
),
clean_fields AS (
    SELECT field_name, order_id, NULLIF(BTRIM(field_value), '') AS field_value
    FROM order_field_values
    WHERE NULLIF(BTRIM(field_value), '') IS NOT NULL
),
order_value_counts AS (
    SELECT field_name, order_id, COUNT(DISTINCT field_value) AS distinct_nonempty_values
    FROM clean_fields
    GROUP BY field_name, order_id
)
SELECT field_name, order_id, distinct_nonempty_values
FROM order_value_counts
WHERE distinct_nonempty_values > 1
ORDER BY field_name, order_id
LIMIT 50;

-- Check whether order-level financial measures differ within the same order.
WITH financial_fields AS (
    SELECT 'Order Profit Per Order' AS field_name, "Order Id" AS order_id, "Order Profit Per Order" AS field_value FROM staging.dataco_raw
    UNION ALL
    SELECT 'Benefit per order', "Order Id", "Benefit per order" FROM staging.dataco_raw
),
clean_fields AS (
    SELECT field_name, order_id, NULLIF(BTRIM(field_value), '') AS field_value
    FROM financial_fields
    WHERE NULLIF(BTRIM(field_value), '') IS NOT NULL
),
order_value_counts AS (
    SELECT field_name, order_id, COUNT(DISTINCT field_value) AS distinct_nonempty_values
    FROM clean_fields
    GROUP BY field_name, order_id
)
SELECT
    field_name,
    COUNT(*) AS affected_orders
FROM order_value_counts
WHERE distinct_nonempty_values > 1
GROUP BY field_name
ORDER BY field_name;

-- Sample affected orders for financial-measure review.
WITH financial_fields AS (
    SELECT 'Order Profit Per Order' AS field_name, "Order Id" AS order_id, "Order Profit Per Order" AS field_value FROM staging.dataco_raw
    UNION ALL
    SELECT 'Benefit per order', "Order Id", "Benefit per order" FROM staging.dataco_raw
),
clean_fields AS (
    SELECT field_name, order_id, NULLIF(BTRIM(field_value), '') AS field_value
    FROM financial_fields
    WHERE NULLIF(BTRIM(field_value), '') IS NOT NULL
),
order_value_counts AS (
    SELECT field_name, order_id, COUNT(DISTINCT field_value) AS distinct_nonempty_values
    FROM clean_fields
    GROUP BY field_name, order_id
)
SELECT field_name, order_id, distinct_nonempty_values
FROM order_value_counts
WHERE distinct_nonempty_values > 1
ORDER BY field_name, order_id
LIMIT 50;

-- SECTION E: PRODUCT, CATEGORY, AND DEPARTMENT MAPPING
-- Product-to-name and product-to-price consistency should be stable within a product ID.
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

-- Product-to-category and product-to-department consistency.
SELECT
    BTRIM("Product Card Id") AS product_id,
    COUNT(DISTINCT NULLIF(BTRIM("Product Category Id"), '')) AS category_count,
    COUNT(DISTINCT NULLIF(BTRIM("Department Id"), '')) AS department_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
GROUP BY BTRIM("Product Card Id")
HAVING COUNT(DISTINCT NULLIF(BTRIM("Product Category Id"), '')) > 1
    OR COUNT(DISTINCT NULLIF(BTRIM("Department Id"), '')) > 1
ORDER BY product_id;

-- Products with a missing category or department reference.
SELECT
    COUNT(*) AS products_with_missing_category
FROM (
    SELECT BTRIM("Product Card Id") AS product_id
    FROM staging.dataco_raw
    WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
    GROUP BY BTRIM("Product Card Id")
    HAVING COUNT(*) FILTER (WHERE NULLIF(BTRIM("Product Category Id"), '') IS NULL) > 0
) AS missing_category_check
UNION ALL
SELECT
    COUNT(*) AS products_with_missing_department
FROM (
    SELECT BTRIM("Product Card Id") AS product_id
    FROM staging.dataco_raw
    WHERE NULLIF(BTRIM("Product Card Id"), '') IS NOT NULL
    GROUP BY BTRIM("Product Card Id")
    HAVING COUNT(*) FILTER (WHERE NULLIF(BTRIM("Department Id"), '') IS NULL) > 0
) AS missing_department_check;

-- Category Id to category name consistency.
SELECT
    BTRIM("Category Id") AS category_id,
    COUNT(DISTINCT "Category Name") AS category_name_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Category Id"), '') IS NOT NULL
GROUP BY BTRIM("Category Id")
HAVING COUNT(DISTINCT "Category Name") > 1
ORDER BY category_id;

-- Department Id to department name consistency.
SELECT
    BTRIM("Department Id") AS department_id,
    COUNT(DISTINCT "Department Name") AS department_name_count
FROM staging.dataco_raw
WHERE NULLIF(BTRIM("Department Id"), '') IS NOT NULL
GROUP BY BTRIM("Department Id")
HAVING COUNT(DISTINCT "Department Name") > 1
ORDER BY department_id;

