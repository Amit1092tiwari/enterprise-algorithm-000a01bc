variable "project_name" {
  description = "Short prefix for project resources"
  type        = string
  default     = "sqldemo"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "East US"
}

variable "location_short" {
  description = "Short abbreviation for region naming convention"
  type        = string
  default     = "eus"
}

variable "sql_admin_username" {
  description = "Administrator login for Azure SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Administrator password for Azure SQL Server"
  type        = string
  sensitive   = true
  default     = "P@ssw0rdEnterprise2026!"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Project    = "Enterprise-SQL-and-Data-Engineering"
    ManagedBy  = "Terraform"
    Repository = "Advancesqlpuzzle"
  }
}
