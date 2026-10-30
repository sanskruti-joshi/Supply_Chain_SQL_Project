-- Run only with psql connected to supply_chain_analytics. 
-- psql -X -W -U postgres -v ON_ERROR_STOP=1 -v replace_staging=on -d supply_chain_analytics -f 'sql\02_import_dataco.sql'

-- This script uses psql's client-side \copy command; it is not plain SQL for a query editor.

-- Safety: the default is to do nothing. To consciously replace the contents
-- of staging.dataco_raw, pass -v replace_staging=on to psql. The truncate,
-- copy, and commit are in one transaction; a failed copy must be rolled back.

\set ON_ERROR_STOP on

\if :{?replace_staging}
\else
\set replace_staging off
\endif

\if :replace_staging
BEGIN;
TRUNCATE TABLE staging.dataco_raw;

\copy staging.dataco_raw ("Type", "Days for shipping (real)", "Days for shipment (scheduled)", "Benefit per order", "Sales per customer", "Delivery Status", "Late_delivery_risk", "Category Id", "Category Name", "Customer City", "Customer Country", "Customer Email", "Customer Fname", "Customer Id", "Customer Lname", "Customer Password", "Customer Segment", "Customer State", "Customer Street", "Customer Zipcode", "Department Id", "Department Name", "Latitude", "Longitude", "Market", "Order City", "Order Country", "Order Customer Id", "order date (DateOrders)", "Order Id", "Order Item Cardprod Id", "Order Item Discount", "Order Item Discount Rate", "Order Item Id", "Order Item Product Price", "Order Item Profit Ratio", "Order Item Quantity", "Sales", "Order Item Total", "Order Profit Per Order", "Order Region", "Order State", "Order Status", "Order Zipcode", "Product Card Id", "Product Category Id", "Product Description", "Product Image", "Product Name", "Product Price", "Product Status", "shipping date (DateOrders)", "Shipping Mode") FROM 'C:\Users\User\Desktop\Practice\Supply_Chain_SQL_Project\data\raw\DataCoSupplyChainDataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252', NULL E'\\N');

COMMIT;
\echo Import committed. Run sql/03_data_profiling.sql against supply_chain_analytics.
\else
\echo No import performed. Review the staging table, then explicitly pass -v replace_staging=on to replace its contents.
\endif
