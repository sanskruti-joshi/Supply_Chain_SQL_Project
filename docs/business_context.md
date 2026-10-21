# Business Context
Scenario
Assume a retailer sources products from suppliers, holds inventory, processes customer orders, and uses shipping providers to fulfill deliveries.

Management wants to understand operational reliability, delivery delays, logistics performance, inventory availability, and opportunities to improve efficiency.
Analytical objective
Build a PostgreSQL-based analytics system that answers operational questions using validated and reproducible SQL.
Core analytical areas
1. Data quality and relational modeling
2. Order and delivery performance
3. Supplier and logistics performance
4. Inventory and replenishment analysis
5. Time-based operational analytics
6. Query optimization and reliability
Scope boundaries
The primary analysis will use the documented source dataset.

Inventory or procurement scenarios may be simulated if the source data does not contain the required information. Simulated values must be identified explicitly and must not be presented as real observations.
Analytical principles
- Define the grain of each table.
- Define metrics before calculating them.
- Validate joins and reconcile totals.
- Distinguish association from causation.
- Document missing data, exclusions, assumptions, and limitations.
- Support recommendations with reproducible evidence.