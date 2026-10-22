
# Data Dictionary

## 1. Overview

The DataCo Smart Supply Chain dataset includes order, customer, product, sales, delivery, and shipping information.

This dictionary is based on the accompanying `DescriptionDataCoSupplyChain.csv` file. Descriptions are reproduced in substance from that source and have not been independently validated against the raw dataset.

## 2. Transaction and Order Information

| Field | Description |
|---|---|
| Type | Type of transaction made. |
| Order Id | Order code. |
| Order Customer Id | Customer order code. |
| Order Status | Order status, including COMPLETE, PENDING, CLOSED, PENDING_PAYMENT, CANCELED, PROCESSING, SUSPECTED_FRAUD, ON_HOLD, and PAYMENT_REVIEW. |
| order date (DateOrders) | Date on which the order is made. |
| Order Item Id | Order item code. |
| Order Item Quantity | Number of products per order. |

## 3. Sales, Discounts, and Profit

| Field | Description |
|---|---|
| Benefit per order | Earnings per order placed. |
| Sales per customer | Total sales per customer. |
| Order Item Discount | Order item discount value. |
| Order Item Discount Rate | Order item discount percentage. |
| Order Item Product Price | Price of products without discount. |
| Order Item Profit Ratio | Order item profit ratio. |
| Sales | Value in sales. |
| Order Item Total | Total amount per order. |
| Order Profit Per Order | Order profit per order. |

## 4. Delivery and Shipping

| Field | Description |
|---|---|
| Days for shipping (real) | Actual shipping days of the purchased product. |
| Days for shipment (scheduled) | Scheduled delivery days of the purchased product. |
| Delivery Status | Delivery status: Advance shipping, Late delivery, Shipping canceled, or Shipping on time. |
| Late_delivery_risk | Categorical variable indicating whether shipping is late (1) or not late (0). |
| Shipping date (DateOrders) | Exact date and time of shipment. |
| Shipping Mode | Shipping mode: Standard Class, First Class, Second Class, or Same Day. |

## 5. Customer Information

| Field | Description |
|---|---|
| Customer Id | Customer ID. |
| Customer Email | Customer's email. |
| Customer Fname | Customer first name. |
| Customer Lname | Customer last name. |
| Customer Password | Masked customer key, according to the source description. |
| Customer Segment | Customer type: Consumer, Corporate, or Home Office. |
| Customer City | City where the customer made the purchase. |
| Customer Country | Country where the customer made the purchase. |
| Customer State | State to which the store where the purchase is registered belongs, according to the source description. |
| Customer Street | Street to which the store where the purchase is registered belongs, according to the source description. |
| Customer Zipcode | Customer ZIP/postal code. |

## 6. Product and Category Information

| Field | Description |
|---|---|
| Category Id | Product category code. |
| Category Name | Description of the product category. |
| Order Item Cardprod Id | Product code generated through the RFID reader, according to the source description. |
| Product Card Id | Product code. |
| Product Category Id | Product category code. |
| Product Description | Product description. |
| Product Image | Link for visiting and purchasing the product. |
| Product Name | Product name. |
| Product Price | Product price. |
| Product Status | Source definition: 1 means not available; 0 means available. |

## 7. Department and Store Information

| Field | Description |
|---|---|
| Department Id | Department code of store. |
| Department Name | Department name of store. |
| Latitude | Latitude corresponding to location of store. |
| Longitude | Longitude corresponding to location of store. |

## 8. Order Destination and Geography

| Field | Description |
|---|---|
| Market | Market where the order is delivered: Africa, Europe, LATAM, Pacific Asia, or USCA. |
| Order City | Destination city of the order. |
| Order Country | Destination country of the order. |
| Order Region | Region of the world where the order is delivered. The source lists regions including Southeast Asia, South Asia, Oceania, Eastern Asia, West Asia, West of USA, US Center, West Africa, Central Africa, North Africa, Western Europe, Northern, Caribbean, South America, East Africa, Southern Europe, East of USA, Canada, Southern Africa, Central Asia, Europe, Central America, Eastern Europe, and South of USA. |
| Order State | State of the region where the order is delivered. |

