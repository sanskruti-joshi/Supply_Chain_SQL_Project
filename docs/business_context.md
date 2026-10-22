
# Business Context: Supply Chain & Operations Intelligence

## 1. Background

Supply chain operations involve coordinating customer orders, product sales, order fulfillment, shipping, and delivery. Understanding operational performance helps businesses identify delays, evaluate shipping methods, assess regional differences, and monitor sales and profitability.

This project uses the DataCo Smart Supply Chain dataset to investigate supply chain and order-delivery performance through SQL-based analysis.

The dataset contains fields related to orders, order items, customers, products, sales, discounts, profitability, shipping duration, delivery status, and geographic locations.

## 2. Business Problem

The objective is to explore how effectively orders are processed and delivered, where delivery delays are concentrated, and how operational performance varies across shipping modes, product categories, customer segments, and geographic regions.

The analysis will focus on identifying measurable patterns and potential areas for operational investigation. The dataset alone may not establish the causes of observed patterns, so findings will be presented as associations unless additional evidence supports causal conclusions.

## 3. Project Objectives

1. **Delivery performance:** Measure delivery timeliness and compare actual shipping duration with scheduled duration.
2. **Regional analysis:** Identify geographic areas with higher delivery-delay rates or different shipping performance.
3. **Shipping analysis:** Compare delivery outcomes across shipping modes.
4. **Product and category analysis:** Examine order volume, sales, discounts, and profitability across product categories.
5. **Customer segment analysis:** Compare order activity and sales across Consumer, Corporate, and Home Office segments.
6. **Operational monitoring:** Develop reusable SQL queries and views for tracking key performance indicators.
7. **Data quality:** Identify missing values, duplicate records, inconsistent values, and potential identifier or granularity issues.
8. **Query performance:** Apply appropriate database design and query optimization techniques.

## 4. Key Business Questions

### A. Order and Delivery Performance

- What proportion of orders are delivered late, on time, or through advance shipping?
- How does actual shipping duration compare with scheduled shipping duration?
- Which regions have the highest delivery-delay rates?
- How does delivery performance vary over time?
- Which shipping modes are associated with higher delay rates?

### B. Sales and Profitability

- Which product categories generate the highest sales?
- Which categories contribute the highest total order profit?
- How do discounts relate to sales and profitability?
- How do sales and order volumes vary across customer segments?
- Are there categories or regions with high sales but comparatively low profitability?

### C. Geographic and Operational Patterns

- Which destination countries and regions account for the largest order volumes?
- Do delivery outcomes differ across geographic markets?
- Are certain shipping modes used more frequently in regions with higher delay rates?
- How does operational performance vary across departments and product categories?

### D. Time-Based Analysis

- How do order volumes and sales change over time?
- Are there identifiable periods with unusually high delivery delays?
- What are the month-over-month changes in sales, order volume, and late-delivery rate?
- Which regions or categories show the largest changes in performance over time?

### E. Data Quality and Reliability

- Are there duplicate order-item records?
- Are order IDs, customer IDs, and product IDs consistent with their expected roles?
- Are there missing or invalid shipping dates, durations, prices, or quantities?
- Do the delivery status and late-delivery risk fields agree?
- Are order-level and order-item-level measures being aggregated at the correct granularity?

## 5. Proposed Key Performance Indicators

| KPI | Proposed Definition |
|---|---|
| Total Orders | Count of distinct order IDs. |
| Total Order Items | Count of distinct order-item IDs, after validating their uniqueness. |
| Total Sales | Sum of the selected sales measure, after confirming its meaning and granularity. |
| Total Order Profit | Sum of order profit at the appropriate level of aggregation. |
| Late-Delivery Rate | Percentage of eligible orders or order items classified as late; the chosen denominator must be documented. |
| On-Time Delivery Rate | Percentage of eligible orders or order items classified as on time; the definition must be documented. |
| Average Actual Shipping Days | Average of actual shipping duration for valid records. |
| Average Shipping Delay | Average difference between actual and scheduled shipping duration, where both values are valid. |
| Average Discount Rate | Average item discount rate, with the aggregation method documented. |

KPI definitions will be finalized after examining the data structure, record granularity, missing values, and the meaning of each measure. Order-level and order-item-level metrics will not be mixed without an explicit aggregation rule.

## 6. Intended Business Value

The analysis is intended to help stakeholders:

- Identify regions and shipping methods that warrant further delivery-performance investigation.
- Understand differences in sales and profitability across products and customer segments.
- Monitor changes in delivery performance and sales over time.
- Establish consistent, reusable definitions for operational KPIs.
- Improve confidence in reporting through documented data-quality checks.
- Produce reproducible SQL analyses that can support operational reporting and decision-making.

These are intended uses of the analysis, not claims that the dataset proves a particular operational improvement.

## 7. Scope and Limitations

### Included

- SQL-based data profiling and quality checks.
- Relational database design and data preparation.
- Order, shipping, sales, profitability, product, customer-segment, and regional analysis.
- Aggregations, joins, CTEs, subqueries, window functions, and time-based analysis.
- Reusable SQL views and query-performance evaluation.

### Limitations

- The dataset's coverage period, completeness, and representativeness must be verified.
- The available fields do not necessarily explain why a delivery was delayed.
- Correlations between shipping methods, discounts, sales, and delivery performance do not establish causation.
- The available data does not currently establish supplier-level performance or inventory availability over time.
- Inventory replenishment, stockout analysis, and supplier analysis may require additional data or a clearly labeled synthetic extension.
- Customer-related identifiers and personal fields will be excluded from public samples unless their publication is explicitly permitted and appropriate.

## 8. Planned Deliverables

- A documented PostgreSQL database schema.
- SQL scripts for profiling, data quality, and data preparation.
- Reproducible SQL analyses answering the business questions above.
- Reusable KPI queries or database views.
- Query optimization examples supported by execution plans.
- A findings report containing validated results, limitations, and recommendations.
- A GitHub repository documenting the methodology and assumptions.
