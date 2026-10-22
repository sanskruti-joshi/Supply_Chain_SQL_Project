-- Run this file with psql while connected to the default "postgres" database:
--   psql -X -W -U postgres -v ON_ERROR_STOP=1 -d postgres -f 'sql\01_database_setup.sql'
--
-- Database creation must run outside a transaction. \gexec executes CREATE
-- DATABASE only when the named database does not already exist.
\set ON_ERROR_STOP on

SELECT format('CREATE DATABASE %I', 'supply_chain_analytics')
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'supply_chain_analytics'
)
\gexec

-- Switch to the project database before creating its schema and staging table.
\connect supply_chain_analytics

SHOW server_encoding;

CREATE SCHEMA IF NOT EXISTS staging;

-- Keep the original CSV column labels and order; quoted identifiers preserve
-- source names, while TEXT avoids coercion during the initial import.
CREATE TABLE IF NOT EXISTS staging.dataco_raw (
    "Type" TEXT,
    "Days for shipping (real)" TEXT,
    "Days for shipment (scheduled)" TEXT,
    "Benefit per order" TEXT,
    "Sales per customer" TEXT,
    "Delivery Status" TEXT,
    "Late_delivery_risk" TEXT,
    "Category Id" TEXT,
    "Category Name" TEXT,
    "Customer City" TEXT,
    "Customer Country" TEXT,
    "Customer Email" TEXT,
    "Customer Fname" TEXT,
    "Customer Id" TEXT,
    "Customer Lname" TEXT,
    "Customer Password" TEXT,
    "Customer Segment" TEXT,
    "Customer State" TEXT,
    "Customer Street" TEXT,
    "Customer Zipcode" TEXT,
    "Department Id" TEXT,
    "Department Name" TEXT,
    "Latitude" TEXT,
    "Longitude" TEXT,
    "Market" TEXT,
    "Order City" TEXT,
    "Order Country" TEXT,
    "Order Customer Id" TEXT,
    "order date (DateOrders)" TEXT,
    "Order Id" TEXT,
    "Order Item Cardprod Id" TEXT,
    "Order Item Discount" TEXT,
    "Order Item Discount Rate" TEXT,
    "Order Item Id" TEXT,
    "Order Item Product Price" TEXT,
    "Order Item Profit Ratio" TEXT,
    "Order Item Quantity" TEXT,
    "Sales" TEXT,
    "Order Item Total" TEXT,
    "Order Profit Per Order" TEXT,
    "Order Region" TEXT,
    "Order State" TEXT,
    "Order Status" TEXT,
    "Order Zipcode" TEXT,
    "Product Card Id" TEXT,
    "Product Category Id" TEXT,
    "Product Description" TEXT,
    "Product Image" TEXT,
    "Product Name" TEXT,
    "Product Price" TEXT,
    "Product Status" TEXT,
    "shipping date (DateOrders)" TEXT,
    "Shipping Mode" TEXT
);

COMMENT ON TABLE staging.dataco_raw IS
    'Raw DataCo CSV staging; source fields are retained as text pending profiling. Contains customer-related data; restrict access.';

-- Later schema design belongs after import and profiling. Do not add keys or
-- relationships until row grain and identifier behavior have been verified.
