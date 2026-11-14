# ====================================================================
# ENTERPRISE AZURE DATA PLATFORM INFRASTRUCTURE (TERRAFORM)
# Author: Amitkumar Tiwari
# Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
# Description: Provisions Azure Data Factory, ADLS Gen2, Azure SQL,
#              and Azure Databricks in a unified architecture.
# ====================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}-${var.location_short}"
  location = var.location
  tags     = var.tags
}

# 2. Azure Data Lake Storage Gen2 (ADLS Gen2)
resource "azurerm_storage_account" "adls" {
  name                     = "st${var.project_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Enables Hierarchical Namespace for ADLS Gen2

  tags = var.tags
}

# ADLS Gen2 Data Containers
resource "azurerm_storage_data_lake_gen2_filesystem" "containers" {
  for_each           = toset(["raw", "curated", "metadata"])
  name               = each.key
  storage_account_id = azurerm_storage_account.adls.id
}

# 3. Azure SQL Database (Server & DB)
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-${var.project_name}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "sqldb" {
  name         = "sqldb-${var.project_name}"
  server_id    = azurerm_mssql_server.sql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  sku_name     = "Basic"
  max_size_gb  = 2

  tags = var.tags
}

# 4. Azure Data Factory (ADF v2)
resource "azurerm_data_factory" "adf" {
  name                = "adf-${var.project_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ADF Linked Service to Azure SQL Database
resource "azurerm_data_factory_linked_service_sql_server" "sql_linked" {
  name            = "Ls_AzureSqlDatabase"
  data_factory_id = azurerm_data_factory.adf.id
  connection_string = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.sqldb.name};User ID=${var.sql_admin_username};Password=${var.sql_admin_password};Trusted_Connection=False;Encrypt=True;"
}

# 5. Azure Databricks Workspace
resource "azurerm_databricks_workspace" "databricks" {
  name                = "dbw-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "standard"

  tags = var.tags
}
