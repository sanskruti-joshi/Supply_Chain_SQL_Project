# Entity-Relationship Diagram

## Purpose and Status

This is a proposed logical model for analysis of the DataCo Smart Supply Chain dataset. It is not yet an implemented or fully validated database schema. Entity names are simplified and may differ from the final PostgreSQL names.

## Proposed Model

```mermaid
erDiagram
    CUSTOMER ||--o{ CUSTOMER_ORDER : places
    CUSTOMER_ORDER ||--|{ ORDER_ITEM : contains
    PRODUCT ||--o{ ORDER_ITEM : appears_in
    CATEGORY ||--o{ PRODUCT : classifies
    DEPARTMENT ||--o{ PRODUCT : groups

    CUSTOMER {
        int customer_id PK
    }

    CUSTOMER_ORDER {
        int order_id PK
        int customer_id FK
        timestamp order_date
        string order_status
        string market
        string shipping_mode
    }

    ORDER_ITEM {
        int order_item_id PK
        int order_id FK
        int product_id FK
        int quantity
        numeric sales
        numeric discount
        numeric profit
        string delivery_status
        int late_delivery_risk
    }

    PRODUCT {
        int product_id PK
        int category_id FK
        int department_id FK
        string product_name
        numeric product_price
        int product_status
    }

    CATEGORY {
        int category_id PK
        string category_name
    }

    DEPARTMENT {
        int department_id PK
        string department_name
    }
```

## Modeling Notes

- The source is denormalized and currently loaded into a text-based staging table; the entities and keys above are proposed.
- The source contains two product identifiers (`Product Card Id` and `Order Item Cardprod Id`). The checks recorded to date found them aligned, but the final foreign-key source must be chosen explicitly.
- Order-item facts and order-level attributes must remain at their appropriate grains. In particular, an order-level profit measure must not be summed once per item row.
- The model and cardinalities remain subject to primary-key, foreign-key, and business-rule validation before implementation.

See [findings_report.md](./findings_report.md) for the current validation evidence and [assumptions_and_limitations.md](./assumptions_and_limitations.md) for outstanding modeling caveats.
