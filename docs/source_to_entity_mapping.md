# Source-to-Entity Mapping

## 1. Purpose and Evidence Basis

This document specifies a proposed mapping from the 53 source columns in
`staging.dataco_raw` to six normalized entities. It is a design specification,
not an implemented schema or migration. No database tables or source data were
changed.

The staging DDL in `sql/01_database_setup.sql` defines all 53 source columns as
`TEXT` and preserves their source labels. The local source CSV was checked
read-only for its header, row count, numeric ranges and scales, date parsing,
key/grain consistency, and the two profit source columns discussed below.
This document also records a prior read-only investigation of the live
`supply_chain_analytics.staging.dataco_raw` table for financial-measure
relationships. No query output or database execution log is committed, so
those reported PostgreSQL results are not independently reproducible from the
repository alone. No customer values are reproduced here.

Validation labels below distinguish:

- **CSV audit** — an aggregate check run directly against the local source CSV
  for this design document.
- **PostgreSQL-confirmed** — a read-only query run against the live
  `supply_chain_analytics.staging.dataco_raw` table. Numeric text was converted
  with guarded casts. These observations describe this staging snapshot; they
  do not establish the business definition of a field.
- **Reported finding** — a result documented in `docs/findings_report.md`.
- **Check defined; result not recorded** — a relevant SQL check exists, but
  its result is not stated in the findings report.
- **Proposed / unresolved** — a modeling decision, not a validated database
  constraint or business definition.

A read-only audit of the local CSV confirmed that `Order Profit Per Order`
and `Benefit per order` contain identical text on all 180,519 source rows.
For each field, values vary within 45,902 orders and are constant within
19,850 single-item orders. This establishes row-level equality and
within-order variation in this extract; it rules out treating either field as
a value that is simply repeated unchanged for every item in every order. It
does not establish that either field is economically an item-level profit
measure, an order-level measure, or suitable for summation. Their names are
not sufficient evidence of business meaning.

## 2. Source-to-Entity Mapping

`Grain` describes the source value's observed or proposed grain. `PK`, `FK`,
`Attribute`, and `Measure` describe its intended role in the proposed model;
`UNRESOLVED` and `EXCLUDED` mean the field is not assigned to a core-table
column at this stage.

| Source column | Destination entity | Proposed PostgreSQL column | Proposed data type | PK/FK/Attribute/Measure | Grain | Mapping rationale | Validation status |
|---|---|---|---|---|---|---|---|
| `Type` | CUSTOMER_ORDER | `transaction_type` | TEXT | Attribute | Order | Source transaction type; held with order context. | CSV audit: one nonblank value per order in this source; definition still source-glossary based. |
| `Days for shipping (real)` | CUSTOMER_ORDER | `actual_shipping_days` | INTEGER | Measure | Order | Actual shipping duration; not an item quantity or money value. | CSV audit: integer values 0–6 and stable within each order; meaning/eligible rows still require business validation. |
| `Days for shipment (scheduled)` | CUSTOMER_ORDER | `scheduled_shipping_days` | INTEGER | Measure | Order | Scheduled duration; keep separate from actual days. | CSV audit: integer values 0–4 and stable within each order; meaning still requires business validation. |
| `Benefit per order` | UNRESOLVED | — | — | UNRESOLVED | Source-row value; business grain unresolved | Exact duplicate of `Order Profit Per Order` on all 180,519 rows, but identical row values do not establish that either is an item-level economic measure. Do not model both as independent measures or assign either to an entity until its meaning and grain are resolved. | Local CSV audit: identical source text on 180,519/180,519 rows; each field varies within 45,902 orders and is constant within 19,850 single-item orders. Business meaning and aggregation unresolved. |
| `Sales per customer` | EXCLUDED | — | — | EXCLUDED | Customer-derived aggregate | A customer aggregate repeated in a transaction-shaped source is not a base customer attribute or order-item fact. No definition, period, or reason to persist the derived aggregate is established. | Source values parse numerically; formula and period are not validated. |
| `Delivery Status` | CUSTOMER_ORDER | `delivery_status` | TEXT | Attribute | Order | Delivery outcome is stable per order in the inspected source; keep distinct from the binary risk flag. | CSV audit: one nonblank value per order. Findings report status/risk count agreement, not independent correctness of the definition. |
| `Late_delivery_risk` | CUSTOMER_ORDER | `late_delivery_risk` | `SMALLINT CHECK (late_delivery_risk IN (0, 1))` | Attribute | Order | Binary indicator; do not treat as interchangeable with the text delivery status. | CSV audit: values 0–1 and stable within each order. Findings report aggregate count agreement with status. |
| `Category Id` | CATEGORY | `category_id` | INTEGER | PK candidate | Category | Candidate category identifier and parent key for products. | CSV audit: 51 distinct nonblank integer values (2–76); matches `Product Category Id` in every source row. Constraints remain proposed. |
| `Category Name` | CATEGORY | `category_name` | TEXT | Attribute | Category | Category label associated with `Category Id`. | CSV audit: no category ID had multiple nonblank names. |
| `Customer City` | UNRESOLVED | — | — | UNRESOLVED | Customer-named; source context unclear | Stable per `Customer Id` in this extract, but the glossary describes it as where the customer made the purchase. Do not assume it is a durable customer-master location. | CSV audit: no within-customer variation; business meaning and ownership are unresolved. |
| `Customer Country` | UNRESOLVED | — | — | UNRESOLVED | Customer-named; source context unclear | Stable per `Customer Id` in this extract, but described as purchase context rather than an unambiguous customer-master address. | CSV audit: no within-customer variation; business meaning and ownership are unresolved. |
| `Customer Email` | CUSTOMER | `email` | TEXT | Attribute | Customer | Plausible customer contact attribute and stable for each customer in this extract. | CSV audit: no within-customer variation; no uniqueness, validity, or contact-permission rule established. |
| `Customer Fname` | CUSTOMER | `first_name` | TEXT | Attribute | Customer | Customer name attribute; use a clear normalized column name. | CSV audit: no within-customer variation. |
| `Customer Id` | CUSTOMER | `customer_id` | INTEGER | PK candidate | Customer | Candidate customer key. `CUSTOMER_ORDER.customer_id` is populated from `Order Customer Id`; the two source IDs matched in this extract. | CSV audit: 20,652 distinct nonblank integer IDs (1–20,757); no leading-zero representations. Candidate key, not yet a database constraint. |
| `Customer Lname` | CUSTOMER | `last_name` | TEXT | Attribute | Customer | Customer name attribute. | CSV audit: no within-customer variation. |
| `Customer Password` | EXCLUDED | — | — | EXCLUDED | Not modeled | Explicitly omit; it is sensitive, not needed by the analytical entities, and must not be copied into normalized tables. | Excluded by scope; value contents are not reported or migrated. |
| `Customer Segment` | CUSTOMER | `customer_segment` | TEXT | Attribute | Customer | Customer classification; stable per customer in this extract. | CSV audit: no within-customer variation; permitted values and business ownership are not independently validated. |
| `Customer State` | UNRESOLVED | — | — | UNRESOLVED | Customer-named; source context unclear | The glossary associates this field with the state of a store where a purchase is registered. Do not assign it to CUSTOMER without resolving that meaning. | CSV audit: no within-customer variation; relationship to a customer, order, or store is unresolved. |
| `Customer Street` | UNRESOLVED | — | — | UNRESOLVED | Customer-named; source context unclear | The glossary describes the street as a store/purchase registration location, not clearly a customer address. No store entity is supported. | CSV audit: no within-customer variation; semantic ownership is unresolved. |
| `Customer Zipcode` | UNRESOLVED | — | — | UNRESOLVED | Customer-named; source context unclear | Postal code should be text if assigned, but its customer-versus-store/purchase meaning must first be decided. | CSV audit: no within-customer variation; semantic ownership is unresolved. |
| `Department Id` | DEPARTMENT | `department_id` | INTEGER | PK candidate; PRODUCT FK source | Department / product | Candidate department key; also the source for `PRODUCT.department_id`. | CSV audit: 11 distinct nonblank integer IDs (2–12); no product was associated with multiple department IDs. Candidate key/FK constraints remain proposed. |
| `Department Name` | DEPARTMENT | `department_name` | TEXT | Attribute | Department | Department label associated with `Department Id`. | CSV audit: no department ID had multiple nonblank names. |
| `Latitude` | UNRESOLVED | — | — | UNRESOLVED | Location; entity not established | Glossary says store location, but no store identifier/entity or supported relationship to DEPARTMENT is established. Do not attach coordinates to DEPARTMENT by assumption. | CSV audit: numeric range −33.93755341 to 48.78193283, up to 8 decimal places; location ownership unresolved. |
| `Longitude` | UNRESOLVED | — | — | UNRESOLVED | Location; entity not established | Same issue as latitude: the location's entity and relationship are not supported by the six-entity scope. | CSV audit: numeric range −158.0259857 to 115.2630768, up to 8 decimal places; location ownership unresolved. |
| `Market` | CUSTOMER_ORDER | `market` | TEXT | Attribute | Order | Order destination market; stable within order in the source audit. | CSV audit: one nonblank value per order; vocabulary/business definition not independently validated. |
| `Order City` | CUSTOMER_ORDER | `destination_city` | TEXT | Attribute | Order | Destination belongs with the order rather than the customer profile. | CSV audit: one nonblank value per order. |
| `Order Country` | CUSTOMER_ORDER | `destination_country` | TEXT | Attribute | Order | Destination belongs with the order. | CSV audit: one nonblank value per order. |
| `Order Customer Id` | CUSTOMER_ORDER | `customer_id` | INTEGER | FK candidate | Order | Customer reference for the order; chosen as the source for `CUSTOMER_ORDER.customer_id`. | CSV audit: matches `Customer Id` on every row; 20,652 distinct nonblank IDs. Proposed FK to `CUSTOMER.customer_id`. |
| `order date (DateOrders)` | CUSTOMER_ORDER | `order_date` | TIMESTAMP WITHOUT TIME ZONE | Attribute | Order | Order timestamp; source contains no timezone offset. | CSV audit: all 180,519 values parsed using the source month/day/year hour:minute format; range 2015-01-01 through 2018-01-31; stable within order. |
| `Order Id` | CUSTOMER_ORDER | `order_id` | INTEGER | PK candidate | Order | Candidate order key and parent key for ORDER_ITEM. | CSV audit: 65,752 distinct nonblank integer IDs (1–77,204); no leading-zero representations. Reported findings give 1–5 items per order. |
| `Order Item Cardprod Id` | ORDER_ITEM | `product_id` | INTEGER | FK candidate | Order item | Product reference on the item row. Use this source for `ORDER_ITEM.product_id`, referencing `PRODUCT.product_id` sourced from `Product Card Id`. | CSV audit: matches `Product Card Id` on every row; 118 distinct product IDs. Proposed FK. |
| `Order Item Discount` | ORDER_ITEM | `discount_amount` | NUMERIC(18,9) | Measure | Order item | Item-row discount amount; retain separately from the discount rate. Candidate amount relation to unit price, quantity, and rate is approximate, not universal. | PostgreSQL-confirmed: range 0–500; `unit price × quantity × discount rate`, rounded to cents, matches 169,385/180,519 rows (93.8%). All 10,028 zero-rate rows have zero amount. Currency meaning/rounding remain provisional. |
| `Order Item Discount Rate` | ORDER_ITEM | `discount_rate` | NUMERIC(11,9) | Measure | Order item | Item-row rate; not interchangeable with the discount amount. | PostgreSQL-confirmed: range 0–0.25; `discount amount / Sales`, rounded to two decimals, matches 179,834/180,519 rows (99.6%). This is an observed relationship, not a universal business formula. |
| `Order Item Id` | ORDER_ITEM | `order_item_id` | INTEGER | PK candidate | Order item | Candidate line/item key and most direct representation of the source row grain. | CSV audit: 180,519 distinct nonblank integer IDs (1–180,519), equal to row count; no duplicate or leading-zero IDs observed. Candidate key, not a database constraint. |
| `Order Item Product Price` | ORDER_ITEM | `unit_product_price` (optional snapshot) | NUMERIC(18,9) | Attribute / measure | Order item | Item price equals `Product Price` exactly in this extract. A separate item-price snapshot may be unnecessary for this dataset; retaining one may matter in a future transactional system where prices change over time. | PostgreSQL-confirmed: exact equality on all 180,519 rows; range 9.989999771–1,999.98999. Whether to retain a redundant snapshot is a physical design decision. |
| `Order Item Profit Ratio` | ORDER_ITEM | `profit_ratio` | NUMERIC(11,9) | Measure | Order item | Retain as a separate item-level ratio. It is not interchangeable with either profit amount field; candidate profit equations do not hold universally. | PostgreSQL-confirmed and reported: range −2.75 to 0.50; 33,784 negative, 1,177 zero, 145,558 positive rows. Strong correlation with profit candidate (0.824); profit divided by item total rounded to cents matches in 173,283/180,519 rows (96.0%), not all. Formula unresolved. |
| `Order Item Quantity` | ORDER_ITEM | `quantity` | INTEGER | Measure | Order item | Number of units on an item row. | CSV audit: integer values 1–5; reported findings state inspected quantities were neither zero nor negative. |
| `Sales` | ORDER_ITEM | `sales_amount` | NUMERIC(18,9) | Measure | Order item | Item-level source measure; distinct from `Order Item Total`. It equals unit price times quantity when rounded to cents in this extract, but this observed relationship alone does not establish a business definition. | PostgreSQL-confirmed: 180,519/180,519 rows match `Order Item Product Price × Order Item Quantity` rounded to cents; exact equality in 126,929 rows. Range 9.989999771–1,999.98999. |
| `Order Item Total` | ORDER_ITEM | `order_item_total` | NUMERIC(18,9) | Measure | Order item | Keep distinct from `Sales`; do not interpret as an order-header total. Its relationship to Sales less discount is close but has exceptions. | PostgreSQL-confirmed: `Sales − Order Item Discount`, rounded to cents, matches 175,906/180,519 rows (97.4%). The remaining 4,613 rows require investigation. Range 7.489999771–1,939.98999. |
| `Order Profit Per Order` | UNRESOLVED | — | — | UNRESOLVED | Source-row value; business grain unresolved | Exact duplicate of `Benefit per order` in this extract. Its name and observed within-order variation do not establish it as an order or item profit measure. Do not assign it to an entity or retain it as an independent measure without a business definition. | Local CSV audit: identical source text on 180,519/180,519 rows; each field varies within 45,902 orders and is constant within 19,850 single-item orders. Business meaning and aggregation unresolved. |
| `Order Region` | CUSTOMER_ORDER | `destination_region` | TEXT | Attribute | Order | Order destination region. | CSV audit: one nonblank value per order. |
| `Order State` | CUSTOMER_ORDER | `destination_state` | TEXT | Attribute | Order | Order destination state; separate from ambiguous `Customer State`. | CSV audit: one nonblank value per order. |
| `Order Status` | CUSTOMER_ORDER | `order_status` | TEXT | Attribute | Order | Lifecycle/status attribute of the order. | CSV audit: one nonblank value per order; allowed values and transition rules not validated. |
| `Order Zipcode` | CUSTOMER_ORDER | `destination_postal_code` | VARCHAR(32) | Attribute | Order | Destination postal code belongs to the order and must remain text to preserve formatting. The source dictionary does not define it. | CSV audit: one nonblank value per order; field semantics/format and maximum width require review. |
| `Product Card Id` | PRODUCT | `product_id` | INTEGER | PK candidate | Product | Chosen canonical product identifier for PRODUCT; referenced by the item FK sourced from `Order Item Cardprod Id`. | CSV audit: 118 distinct nonblank integer IDs (19–1,363); matches `Order Item Cardprod Id` on every row. Candidate key, not a database constraint. |
| `Product Category Id` | PRODUCT | `category_id` | INTEGER | FK candidate | Product | Product-to-category reference; use rather than duplicating category name in PRODUCT. | CSV audit: matches `Category Id` on every row; no product had multiple category IDs. Proposed FK to CATEGORY. |
| `Product Description` | PRODUCT | `description` | TEXT | Attribute | Product | Product descriptive attribute, stable by product in this extract. | CSV audit: no product ID had multiple nonblank descriptions; content quality not assessed. |
| `Product Image` | PRODUCT | `image_url` | TEXT | Attribute | Product | Source-described product image link; store the text value, not downloaded image content. | CSV audit: no product ID had multiple nonblank values; URL validity not assessed. |
| `Product Name` | PRODUCT | `product_name` | TEXT | Attribute | Product | Product name, stable by product in this extract. | CSV audit: no product ID had multiple nonblank names. |
| `Product Price` | PRODUCT | `product_price` | NUMERIC(18,9) | Attribute / measure | Product | Product price is identical to `Order Item Product Price` on every row in this extract. A separate item-price snapshot may be unnecessary for this dataset, but could be important in a future transactional system with changing prices. | PostgreSQL-confirmed: exact equality on all 180,519 rows; range 9.989999771–1,999.98999. Business definition/rounding remain provisional. |
| `Product Status` | PRODUCT | `product_status` | `SMALLINT CHECK (product_status IN (0, 1))` | Attribute | Product | Source dictionary defines 0 as available and 1 as unavailable; preserve the source coding. | CSV audit: only 0 observed. The documented meaning of 1 is source-glossary based; do not infer availability history. |
| `shipping date (DateOrders)` | CUSTOMER_ORDER | `shipping_date` | TIMESTAMP WITHOUT TIME ZONE | Attribute | Order | Shipment timestamp is stable within order in this source; no timezone is included. | CSV audit: all 180,519 values parsed; range 2015-01-03 through 2018-02-06; stable within order. |
| `Shipping Mode` | CUSTOMER_ORDER | `shipping_mode` | TEXT | Attribute | Order | Shipping mode is an order-level attribute in this source. | CSV audit: one nonblank value per order; documented mode vocabulary is not treated as an enforced constraint. |

## 3. Entity Definitions

### CUSTOMER

- **One row represents:** One source customer identified by `Customer Id`.
- **Primary key:** `customer_id` (candidate source key; proposed `INTEGER`).
- **Foreign keys:** None.
- **Attributes:** `first_name`, `last_name`, `email`, and `customer_segment`.
- **Measures:** None.
- **Relationships:** One CUSTOMER may place many CUSTOMER_ORDER rows; each order references one customer.
- **Boundary:** Customer city/country/state/street/postal code are not assigned yet. Although each is stable per ID in this extract, the source glossary describes some as purchase/store context. Resolve ownership before putting them in CUSTOMER or CUSTOMER_ORDER.

### CUSTOMER_ORDER

- **One row represents:** One order identified by `Order Id`.
- **Primary key:** `order_id` (candidate source key; proposed `INTEGER`).
- **Foreign keys:** `customer_id` to CUSTOMER, sourced from `Order Customer Id`.
- **Attributes:** `transaction_type`, `order_date`, `order_status`, `market`, destination city/country/region/state/postal code, `shipping_mode`, `delivery_status`, `late_delivery_risk`, `shipping_date`.
- **Measures:** `actual_shipping_days` and `scheduled_shipping_days`.
- **Relationships:** One CUSTOMER_ORDER belongs to one CUSTOMER and contains one or more ORDER_ITEM rows; each ORDER_ITEM belongs to one order.
- **Boundary:** `Order Profit Per Order` and `Benefit per order` are identical source-row values but vary within many orders. Neither is assigned to CUSTOMER_ORDER or ORDER_ITEM; their business meaning and economic grain remain unresolved.

### ORDER_ITEM

- **One row represents:** One source order line/item identified by `Order Item Id`.
- **Primary key:** `order_item_id` (candidate source key; proposed `INTEGER`).
- **Foreign keys:** `order_id` to CUSTOMER_ORDER; `product_id` to PRODUCT.
- **Attributes and measures:** `quantity`, `discount_amount`, `discount_rate`, `sales_amount`, `order_item_total`, and `profit_ratio`. `unit_product_price` is optional because it duplicates PRODUCT.`product_price` in this extract.
- **Relationships:** Each item belongs to one order and references one product. A product may appear on many items.
- **Boundary:** `Sales` and `Order Item Total` are separate item-level measures with an observed but imperfect arithmetic relationship. Do not treat them as equivalent. Do not store both duplicate profit source fields as independent measures; resolve their meaning before deciding whether one belongs here.

### PRODUCT

- **One row represents:** One product identified by `Product Card Id`.
- **Primary key:** `product_id` (candidate source key; proposed `INTEGER`).
- **Foreign keys:** `category_id` to CATEGORY; `department_id` to DEPARTMENT.
- **Attributes and measures:** `product_name`, `description`, `image_url`, `product_price`, and `product_status`.
- **Relationships:** One PRODUCT may appear on many ORDER_ITEM rows; each product references one category and one department in the proposed model.
- **Boundary:** `Product Price` equals item-level `Order Item Product Price` throughout this extract. The separate item-price snapshot may be redundant here, but may be useful for preserving transaction-time price in future systems.

### CATEGORY

- **One row represents:** One product category identified by `Category Id`.
- **Primary key:** `category_id` (candidate source key; proposed `INTEGER`).
- **Foreign keys:** None.
- **Attributes and measures:** `category_name`; no measures.
- **Relationships:** One CATEGORY may classify many PRODUCT rows.

### DEPARTMENT

- **One row represents:** One department identified by `Department Id`.
- **Primary key:** `department_id` (candidate source key; proposed `INTEGER`).
- **Foreign keys:** None.
- **Attributes and measures:** `department_name`; no measures.
- **Relationships:** One DEPARTMENT may group many PRODUCT rows.
- **Boundary:** No STORE entity is proposed. The source does not establish a store identifier or a relationship that would justify assigning latitude/longitude or store/purchase attributes to DEPARTMENT.

## 4. Key and Relationship Decisions

| Key/relationship | Proposed decision | Evidence and status |
|---|---|---|
| `Customer Id` | `CUSTOMER.customer_id` primary key candidate. | 20,652 distinct nonblank integer IDs observed; exact source match with `Order Customer Id`. Uniqueness/non-nullness in the target remains to be enforced and tested. |
| `Order Customer Id` → `Customer Id` | `CUSTOMER_ORDER.customer_id` foreign key, sourced from `Order Customer Id`. | Values matched in every row of the CSV audit; the findings report also records a match. Proposed FK; no constraint exists yet. |
| `Order Id` | `CUSTOMER_ORDER.order_id` primary key candidate. | 65,752 distinct nonblank IDs; findings report 1–5 item rows per order. Proposed PK. |
| `Order Item Id` | `ORDER_ITEM.order_item_id` primary key candidate. | 180,519 distinct IDs for 180,519 CSV rows; findings report no duplicate non-empty item IDs. Proposed PK. |
| `Product Card Id` | `PRODUCT.product_id` primary key candidate. | 118 distinct IDs; product name, price, category, department, description, image, and status were each stable by product in the CSV audit. Proposed PK. |
| `Order Item Cardprod Id` → `Product Card Id` | `ORDER_ITEM.product_id` references `PRODUCT.product_id`. | Exact equality on all source rows in the CSV audit; findings report no missing/mismatched product identifiers. This supports the mapping, but target FK validation is still required. |
| `Category Id` | `CATEGORY.category_id` primary key candidate. | 51 distinct IDs; category names were stable by ID in the CSV audit. Proposed PK. |
| `Product Category Id` → `Category Id` | `PRODUCT.category_id` references `CATEGORY.category_id`. | Exact equality between the two source columns in the CSV audit; product category mapping was stable. Proposed FK; target orphan check remains required. |
| `Department Id` | `DEPARTMENT.department_id` primary key candidate and source for `PRODUCT.department_id`. | 11 distinct IDs; department names stable and product-to-department mapping consistent in the CSV audit. Proposed PK/FK; no STORE relationship inferred. |

These are validated relationships only within the inspected CSV snapshot; they
are not PostgreSQL constraints or guarantees for future loads. Before creating
constraints, repeat null, duplicate, orphan, and cardinality checks against the
staging data that will actually be migrated.

## 5. Grain and Measure Decisions

### Order-level attributes

The CSV audit found one nonblank value per `Order Id` for `Delivery Status`,
`Late_delivery_risk`, both shipping-day fields, and `shipping date (DateOrders)`.
The same was true for order date/status, type, shipping mode, market, and
destination fields. These are therefore proposed for CUSTOMER_ORDER, not
repeated on every ORDER_ITEM row. They are source-snapshot observations, not
guarantees for other loads.

| Source field | Proposed grain | Decision |
|---|---|---|
| `Delivery Status` | Order | CUSTOMER_ORDER attribute. Keep the descriptive outcome separate from the risk indicator. |
| `Late_delivery_risk` | Order | CUSTOMER_ORDER 0/1 attribute. Findings report count agreement with Delivery Status; this does not prove either field's business correctness. |
| `Days for shipping (real)` | Order | CUSTOMER_ORDER duration measure, separate from scheduled days. |
| `Days for shipment (scheduled)` | Order | CUSTOMER_ORDER duration measure, separate from actual days. |
| `Shipping date (DateOrders)` | Order | CUSTOMER_ORDER timestamp. |
| `Sales per customer` | Customer-derived aggregate; excluded | Do not store a duplicated aggregate without a defined formula, period, and justified use. It is not interchangeable with sales on an order item. |

### Profit fields with unresolved grain

`Order Profit Per Order` and `Benefit per order` are identical source-row
values in the inspected CSV. Each varies within 45,902 orders and is constant
within 19,850 single-item orders. This rules out a simple interpretation as
an order-level value repeated unchanged on every item row, but does not prove
that either is an item-level profit amount. Keep both unmapped in the
normalized schema until their business definitions and valid aggregation
rules are established; do not sum either by order or item based on its name.

### Order-item-level measures

`Order Item Id` is unique per source row in this CSV, supporting an
order-item-grain staging representation. These fields are provisionally assigned to ORDER_ITEM based on the source
order-item grain and PostgreSQL observations. Their observed arithmetic
relationships do not by themselves establish business definitions:

- `Order Item Quantity`
- `Order Item Discount` (amount) and `Order Item Discount Rate` (rate)
- `Order Item Product Price` (transaction/item price)
- `Sales`
- `Order Item Total`
- `Order Item Profit Ratio`

PostgreSQL confirms `Sales` equals `Order Item Product Price × Order Item
Quantity` rounded to cents on all rows. `Order Item Total` equals `Sales −
Order Item Discount` rounded to cents on 175,906 rows; the other 4,613 rows
remain unexplained. `Order Item Product Price` equals PRODUCT.`product_price`
on all rows, so retaining it as a separate item snapshot may be unnecessary
for this dataset. Discount amount, discount rate, and profit ratio remain
separate measures: the candidate discount equations match most, but not all,
rows, and candidate profit equations also have exceptions. These are
PostgreSQL-confirmed source patterns, not validated business formulas.

`Sales`, `Order Item Total`, and `Order Item Product Price` are not
interchangeable. `Order Profit Per Order` and `Benefit per order` are exact
duplicates in this extract, but their names and variation do not establish
whether either is item profit or order profit. Do not persist them as two
independent measures or use them in profit metrics until their meaning and
aggregation are validated. `Sales per customer` remains a separate excluded
derived aggregate.
`Order Item Profit Ratio` is a ratio, not a currency measure.

## 6. PostgreSQL Type Recommendations

Types in the mapping are target recommendations, not types already present in
staging. All staging columns are currently `TEXT`.

- **Identifiers:** Use `INTEGER` for the candidate IDs. The source audit found
  integer-form IDs with current maxima of 20,757 (`Customer Id`), 77,204
  (`Order Id`), 180,519 (`Order Item Id`), 1,363 (product), 76 (category), and
  12 (department), all well within PostgreSQL `INTEGER`. Revisit only if future
  source systems expand the ranges or identifiers cease to be numeric.
- **Counts and durations:** Use `INTEGER` for item quantity and shipping-day
  counts; observed ranges are 1–5, 0–6, and 0–4 respectively. Apply domain
  checks only after business rules (especially whether zero shipping days is
  valid) are confirmed.
- **Financial values:** Use `NUMERIC(18,9)` provisionally for amounts. The
  source CSV contains up to nine fractional digits, including values such as
  `9.989999771`; do not silently round to two decimals during migration.
  Confirm whether these digits reflect source export artifacts, the intended
  currency precision, and acceptable integer range before setting final
  precision/scale.
- **Rates:** `NUMERIC(11,9)` accommodates the observed profit-ratio range
  −2.75 to 0.50 and discount-rate range 0–0.25 at observed scale. Formula and
  rounding policy remain unvalidated.
- **Timestamps:** Use `TIMESTAMP WITHOUT TIME ZONE`; source strings parse as
  month/day/year hour:minute and carry no timezone offset. Confirm timezone
  semantics before interpreting cross-region chronology.
- **Postal codes:** Use `VARCHAR(32)` provisionally for `Order Zipcode` and
  any postal code later approved for modeling. Never cast postal codes to
  integers; doing so could destroy leading zeros or formatting.
- **Coordinates:** If ownership is later resolved, `NUMERIC(11,8)` preserves
  the observed coordinate precision and ranges. They remain UNRESOLVED and
  are not assigned to one of the six entities now.
- **Descriptive values:** Use `TEXT` for names, descriptions, URLs, statuses,
  modes, segments, geography labels, email, and other unbounded source text.
  Avoid arbitrary length limits until observed maximum lengths and application
  requirements are reviewed.
- **Flags:** Use `SMALLINT` with an eventual 0/1 check for `Late_delivery_risk`
  and `Product Status`; do not infer boolean semantics beyond the source
  coding. `Product Status` was 0 on all rows in this CSV snapshot.

## 7. Outstanding Assumptions Before Table Creation

1. Establish the business meaning and economic grain of the duplicate
   `Order Profit Per Order` and `Benefit per order` fields. The local CSV
   audit finds identical text on all 180,519 rows, with within-order
   variation in 45,902 orders and one value in 19,850 single-item orders.
   This is inconsistent with a value repeated unchanged across all item rows
   of each order, but does not prove either field is item-level profit. Decide
   whether either belongs in the model and define its valid aggregation
   before modeling or reporting it.
2. Investigate the 4,613 rows where `Order Item Total` does not equal `Sales −
   Order Item Discount` rounded to cents. No explanation is established.
   Confirm the intended meaning and reporting use of these two separate
   measures before selecting a canonical sales metric.
3. Confirm whether the observed all-row `Sales = unit price × quantity`
   relationship is the intended sales definition, rather than treating an
   arithmetic match as a business rule. Decide whether to retain
   `Order Item Product Price` as a transaction-time snapshot despite its exact
   equality with `Product Price` throughout this extract.
4. Define formulas and aggregation rules for discount amount, discount rate,
   profit, benefit, and profit ratio. The candidate discount relationships
   have exceptions, and the profit ratio's strong relationship with the
   profit candidate does not make candidate profit equations universal.
   Determine whether `Order Item Profit Ratio` may be aggregated at all.
5. Define the formula, reference period, and intended use of `Sales per
   customer`; otherwise keep it out of the six base entities.
6. Decide whether `Customer City`, `Customer Country`, `Customer State`,
    `Customer Street`, and `Customer Zipcode` describe a customer address,
    purchase context, or store location. Stable values per customer do not by
    themselves prove semantic ownership.
7. Resolve the entity for `Latitude` and `Longitude`. The source description
    says store location, but no store identifier or supported relationship is
    present; do not create a STORE table or attach coordinates to DEPARTMENT
    without new evidence.
8. Confirm whether CUSTOMER attributes (particularly segment and contact
    fields) are durable customer-master data or snapshots, and decide handling
    for future changes. The CSV audit only establishes within-extract
    consistency.
9. Confirm the canonical key and FK mappings against the actual migration
    batch, including null/blank handling, duplicate keys, orphan rows, and
    entity cardinalities. Source-query equality checks do not replace target
    constraints.
10. Decide whether source IDs must remain numeric or be preserved as opaque
    identifiers if future source files introduce nonnumeric or leading-zero
    values; the current extract contains numeric IDs without leading zeros.
11. Finalize numeric precision/scale and currency rounding, including whether
    up to nine source decimal places should be preserved or normalized under
    a documented rule.
12. Confirm timestamp timezone interpretation and the intended format and
    validity rules for `Order Zipcode`, which the source dictionary does not
    define.
13. Decide nullability, whitespace normalization, status-domain checks,
    uniqueness constraints, and FK enforcement behavior after validation;
    no such target constraints have been created.

Until these decisions are settled, the mapping is suitable for schema review
but not a complete migration contract for unresolved columns or measures.
