# SAP b1 SQL queries
### An anonymised collection of SAP Business One SQL queries originally developed and used at Korea Foods.

<br> 

## Overview
This repository showcases anonymised SQL queries written for **SAP Business One** to support reporting, automation, and decision-making.  
They were originally designed and deployed at **Korea Foods (£78M turnover, 20+ stores in the UK)**, where I worked as the company’s first in-house Data Scientist.  

<br> 

## Key Stack
- T-SQL on Microsoft SQL Server
- SAP Business One database schema (OITM, OITW, OWOR, OPCH, OINV, ITT1, etc.)
- User Defined Tables (UDT) & Fields (UDF)
- Query Manager and Formatted Search integration
- Used as part of automation pipelines (MSSQL Agent) and BI dashboards (Tableau)

<br>

## Business Impact
- Enabled **reliable daily stock history** → contributed to **£3.9M revenue uplift** by preventing stock-outs  
- Automated reporting and data validation → saved **5,000+ staff hours annually**  
- Improved cost accuracy with **landed cost validation and moving averages** → provided robust reference for pricing decisions  
- Built fraud detection queries → uncovered **£700K in irregular membership claims**  

<br> 

### The queries demonstrate:  
- Practical use of **SAP B1 database structure** (OITM, OITW, OWOR, OPCH, OINV, etc.)  
- Handling of **business-specific requirements** such as inventory availability, landed cost tracking, BOM analysis, sales and returns reporting  
- **Performance gains** from replacing manual reporting with automated SQL views and formatted searches  

<br> 

## Query Catalogue

| File name | Purpose | Notes |
|-----------|---------|-------|
| `inventory_availability_by_warehouse.sql` | Shows available stock per item across multiple warehouses, adjusted for sales units. | Used by purchasing and sales to check real availability. |
| `bp_group_init.sql` | Creates and initialises a user-defined BP group table. | Simplified a messy customer code structure by introducing clear grouping rules, making it easier to segment and analyse business partners. |
| `production_material_usage_by_month.sql` | Tracks issued raw materials for a given finished good across 12 months. | Supports cost tracking and forecast of component usage. |
| `landed_cost_moving_avg.sql` | Calculates landed cost per UOM and a 3-period moving average. | Key reference for pricing and margin validation. |
| `bom_parent_item_lookup.sql` | Finds parent items (finished goods) that consume a given component in BOM. | Useful for substitution and dependency analysis. |
| `sales_and_returns_report.sql` | Combines invoice and credit memo lines with flexible partner/item filters. | Saved finance & sales teams manual reconciliations. |
| `fs_autofill_hscode.sql` | Formatted search to auto-fill Container Code when creating AP/PO docs. | Reduced manual entry errors in purchasing. |
| `first_import_items_history.sql` | Shows items first imported in AP invoices, marking new products. | Helped track new SKUs and supplier performance. |

<br> 

## Disclaimer
All business-specific item codes, warehouse codes, and internal identifiers have been anonymised.  
User-defined field names are illustrative and may differ from actual implementations.
