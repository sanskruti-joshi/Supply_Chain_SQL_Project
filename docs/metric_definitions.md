# Metric Definitions

## Status and Grain

The source is being treated as order-item-grain data, but the SQL project has not yet implemented downstream metric queries. The definitions below are analytical conventions to use or revise after validation; they are not a claim that the metrics have already been calculated. Unless otherwise stated, item-level rates use valid order-item rows as their denominator.

| Metric | Proposed definition | Grain | Status / caveat |
|---|---|---|---|
| Total orders | Count distinct nonblank `Order Id`. | Order | Profiled as 65,752 in the current source. |
| Total order items | Count distinct nonblank `Order Item Id`, after confirming uniqueness. | Order item | Profiled as 180,519 distinct IDs; candidate key checks are not a normalized-schema constraint. |
| Late-delivery rate | Late eligible item rows divided by eligible item rows; classify using `Delivery Status = 'Late delivery'` and separately reconcile with `Late_delivery_risk`. | Order item | Denominator, treatment of canceled/unknown statuses, and order-level reporting rule must be explicit. |
| On-time delivery rate | Eligible item rows with `Delivery Status = 'Shipping on time'` divided by eligible item rows. | Order item | Keep distinct from advance shipping; use the same eligibility rule as the late rate. |
| Advance-shipping rate | Eligible item rows with `Delivery Status = 'Advance shipping'` divided by eligible item rows. | Order item | Use the same eligibility rule as other delivery-status rates. |
| Average actual shipping days | Average valid `Days for shipping (real)` values. | Order item | Confirm the field definition and valid numeric range before reporting. |
| Average shipping-duration variance | Average of actual shipping days minus scheduled shipping days where both values are valid. Positive values indicate more actual days than scheduled. | Order item | A duration comparison, not necessarily a customer-promise breach definition. |
| Total sales | Sum the selected item-level measure only after choosing between `Sales` and `Order Item Total` and validating its meaning. | Must be selected | Not finalized; `Sales per customer` is described as customer-level and must not be summed once per item row. |
| Total profit | Sum an item-grain profit measure only after identifying and validating one. | Must be selected | `Order Profit Per Order` is order-level and repeated on item rows; do not sum it at item grain. |
| Average discount | Report either average `Order Item Discount` (currency amount) or average `Order Item Discount Rate` (rate), with the exact field and weighting stated. | Order item | These fields are not interchangeable; decide whether the mean is row-weighted or quantity-weighted. |

For source profiling and data-quality evidence, see [findings_report.md](./findings_report.md). Related interpretation limits are in [assumptions_and_limitations.md](./assumptions_and_limitations.md).
