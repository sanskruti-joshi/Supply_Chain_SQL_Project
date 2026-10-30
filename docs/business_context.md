# Business Context

## Background

Supply chain operations coordinate customer orders, products, fulfillment, shipping, and delivery. This project uses the DataCo Smart Supply Chain dataset to explore order and delivery performance with PostgreSQL and SQL.

## Business Problem

The analysis asks where delivery outcomes and sales patterns vary across shipping modes, destinations, product categories, and customer segments. The dataset can show associations and reporting patterns; it does not, by itself, establish why an outcome occurred or prove that a particular operational change would improve it.

## Objectives

- Profile and validate the source data before relying on its measures or relationships.
- Describe delivery outcomes by shipping mode, destination, and time.
- Explore sales, discounts, and profitability by product and customer segment after confirming suitable aggregation rules.
- Develop reusable, clearly defined operational measures.
- Document a relational model and evaluate query performance as those components are implemented.

## Business Questions

### Delivery

- What share of eligible order items are late, on time, or shipped in advance?
- How do actual and scheduled shipping durations compare?
- How do delivery outcomes vary by shipping mode, destination, and time?

### Sales and products

- How do sales and order activity vary by product category and customer segment?
- How do discounts and profitability vary across those groups?
- Which destinations or categories combine high sales with relatively low profit?

### Data reliability

- Are order-item identifiers unique and are entity relationships consistent?
- Are source dates and numeric fields usable for analysis?
- Are delivery status and late-delivery risk consistent?
- Are order-level measures being aggregated without multiplying them across item rows?

## Scope

The current implemented work is focused on raw-data setup, import, profiling, and data-quality investigation. Delivery, sales, inventory, supplier, normalized-schema, reusable-view, and optimization analyses remain planned until corresponding SQL and validated results are present.

The source contains order, customer, product, geographic, and shipping fields. It does not currently provide supplier identifiers or inventory/replenishment history sufficient to measure supplier performance, stockouts, or inventory risk. Such analysis would require another dataset or an explicitly identified synthetic extension.

For measure definitions and their validation status, see [metric_definitions.md](./metric_definitions.md). For validated observations and remaining work, see [findings_report.md](./findings_report.md).
