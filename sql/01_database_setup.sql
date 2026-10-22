-- Run this script while connected to the default
-- "postgres" database, not the project database.


CREATE DATABASE supply_chain_analytics;

SELECT
    current_database() AS database_name,
    current_user AS database_user,
    version() AS postgresql_version;