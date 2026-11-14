# ☁️ Azure Cloud Infrastructure as Code (IaC)

This directory provides automated Infrastructure-as-Code (IaC) definitions to provision the complete cloud data platform required for the **Azure Data Factory Metadata Ingestion** and **Databricks Spark Hive** architectures.

---

## 🏗️ Architecture Components Provisioned

```
┌────────────────────────────────────────────────────────┐
│               Azure Resource Group                     │
│                                                        │
│   ┌───────────────────┐        ┌───────────────────┐   │
│   │  Azure Data Lake  │───────▶│ Azure Data Factory│   │
│   │    Storage Gen2   │        │     (ADF v2)      │   │
│   │ (raw/curated/meta)│        └─────────┬─────────┘   │
│   └─────────┬─────────┘                  │             │
│             │                            ▼             │
│             │                  ┌───────────────────┐   │
│             └─────────────────▶│ Azure SQL Database│   │
│                                │   (demo schema)   │   │
│                                └───────────────────┘   │
│                                                        │
│   ┌────────────────────────────────────────────────┐   │
│   │          Azure Databricks Workspace            │   │
│   │         (PySpark / Delta Lake Cluster)         │   │
│   └────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Deployment Option 1: Terraform

### Prerequisites
- [Terraform CLI (>= 1.5.0)](https://www.terraform.io/downloads.html)
- [Azure CLI (`az`)](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) logged in via `az login`

### Commands
```bash
# 1. Initialize Terraform Providers
cd "Microsoft Azure/Infrastructure as Code"
terraform init

# 2. Preview Resource Creation
terraform plan

# 3. Provision Infrastructure
terraform apply -auto-approve
```

### Clean Up (Tear Down)
```bash
terraform destroy -auto-approve
```

---

## ⚡ Deployment Option 2: Azure Bicep

### Deploy via Azure CLI
```bash
# 1. Create Target Resource Group
az group create --name rg-sqldemo-dev-eus --location eastus

# 2. Deploy Bicep Template
az deployment group create \
  --resource-group rg-sqldemo-dev-eus \
  --template-file azuredeploy.bicep \
  --parameters sqlAdminPassword='YourStrongPassword123!'
```
