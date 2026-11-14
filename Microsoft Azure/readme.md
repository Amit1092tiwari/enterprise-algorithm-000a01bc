# Microsoft Azure Data Engineering Demos

This directory contains cloud architecture demonstrations, end-to-end data pipelines, architectural guides, reproducible DDL scripts, and automated Infrastructure-as-Code (Terraform & Bicep) for Microsoft Azure data platforms.

---

## Contents

### 1. [Infrastructure as Code (IaC)](./Infrastructure%20as%20Code/)
- **Terraform:** [`main.tf`](./Infrastructure%20as%20Code/main.tf), `variables.tf`, `outputs.tf`
- **Bicep:** [`azuredeploy.bicep`](./Infrastructure%20as%20Code/azuredeploy.bicep)
- **Overview:** One-click deployment provisioning the complete Azure cloud footprint: Azure Data Factory (v2), Azure Data Lake Storage Gen2 (`raw`, `curated`, `metadata`), Azure SQL Database, and Azure Databricks Workspace.

### 2. [Azure Data Factory Metadata Demo](./Data%20Factory%20Metadata%20Demo/)
- **Guide:** [`DATA_FACTORY_METADATA_DEMO.md`](./Data%20Factory%20Metadata%20Demo/DATA_FACTORY_METADATA_DEMO.md)
- **Scripts:** [`Data Factory SQL DDL Scripts.sql`](./Data%20Factory%20Metadata%20Demo/Data%20Factory%20SQL%20DDL%20Scripts.sql)
- **Data:** `Customer_1.txt`, `Customer_2.txt`, `Customer_3.txt`
- **Overview:** Demonstrates automated file and pipeline metadata capture, dynamic pipeline auditing, and Table-Valued Parameter (TVP) loading in Azure Data Factory (ADF) connecting to Azure SQL Database.

### 3. [Databricks Spark Hive Demo](./Databricks%20Spark%20Hive%20Demo/)
- **Guide:** [`DATABRICKS_SPARK_HIVE_DEMO.md`](./Databricks%20Spark%20Hive%20Demo/DATABRICKS_SPARK_HIVE_DEMO.md)
- **Workspace:** [`SuppliersAndParts.dbc`](./Databricks%20Spark%20Hive%20Demo/SuppliersAndParts.dbc) (Databricks export with 8 PySpark notebooks)
- **Scripts:** [`SuppliersAndPartsDDL.sql`](./Databricks%20Spark%20Hive%20Demo/SuppliersAndPartsDDL.sql)
- **Data:** `Suppliers.csv`, `Parts.csv`, `Shipments.csv`
- **Overview:** Demonstrates Azure Databricks PySpark and Delta Lake (Hive metastore) ETL integration, Key Vault secret scopes, ADLS Gen2 mounting, and sequential ADF pipeline orchestration.
