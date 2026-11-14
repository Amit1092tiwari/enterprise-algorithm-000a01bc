output "resource_group_name" {
  description = "Name of the provisioned Azure Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "adls_storage_account_name" {
  description = "Name of the ADLS Gen2 Storage Account"
  value       = azurerm_storage_account.adls.name
}

output "sql_server_fqdn" {
  description = "Fully Qualified Domain Name of Azure SQL Server"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Name of the provisioned Azure SQL Database"
  value       = azurerm_mssql_database.sqldb.name
}

output "data_factory_name" {
  description = "Name of the provisioned Azure Data Factory"
  value       = azurerm_data_factory.adf.name
}

output "databricks_workspace_url" {
  description = "URL of the provisioned Azure Databricks workspace"
  value       = azurerm_databricks_workspace.databricks.workspace_url
}
