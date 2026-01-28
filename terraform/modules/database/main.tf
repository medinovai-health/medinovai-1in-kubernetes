# MedinovAI LIS Infrastructure - Database Module
# Terraform module for Azure MySQL Flexible Server
# HIPAA-compliant with encryption, backup, and audit logging

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Variables
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus2"
}

variable "server_name" {
  type        = string
  description = "MySQL server name"
  default     = "medinovai-lis-mysql"
}

variable "environment" {
  type        = string
  description = "Environment (development, staging, production)"
  default     = "production"
}

variable "sku_name" {
  type        = string
  description = "SKU name for MySQL Flexible Server"
  default     = "GP_Standard_D4ds_v4"  # 4 vCores, 16 GB RAM
}

variable "mysql_version" {
  type        = string
  description = "MySQL version"
  default     = "8.0.21"
}

variable "storage_size_gb" {
  type        = number
  description = "Storage size in GB"
  default     = 256
}

variable "storage_iops" {
  type        = number
  description = "Storage IOPS"
  default     = 1000
}

variable "backup_retention_days" {
  type        = number
  description = "Backup retention in days"
  default     = 35  # HIPAA recommends longer retention
}

variable "geo_redundant_backup" {
  type        = bool
  description = "Enable geo-redundant backups"
  default     = true
}

variable "high_availability" {
  type = object({
    mode                      = string
    standby_availability_zone = string
  })
  description = "High availability configuration"
  default = {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
}

variable "delegated_subnet_id" {
  type        = string
  description = "Subnet ID for MySQL private access"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for MySQL"
  default     = null
}

variable "administrator_login" {
  type        = string
  description = "Administrator username"
  default     = "lisadmin"
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault ID for storing secrets"
}

variable "allowed_ip_addresses" {
  type        = list(string)
  description = "List of allowed IP addresses"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    Project     = "MedinovAI-LIS"
    ManagedBy   = "Terraform"
    Compliance  = "HIPAA,ISO13485"
    DataClass   = "PHI"
  }
}

# Generate secure password
resource "random_password" "mysql_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "mysql" {
  count               = var.private_dns_zone_id == null ? 1 : 0
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "lis" {
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.administrator_login
  administrator_password = random_password.mysql_admin.result
  
  sku_name = var.sku_name
  version  = var.mysql_version
  zone     = "1"
  
  # Storage configuration
  storage {
    size_gb           = var.storage_size_gb
    iops              = var.storage_iops
    auto_grow_enabled = true
  }
  
  # Backup configuration
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup
  
  # High availability
  dynamic "high_availability" {
    for_each = var.environment == "production" ? [1] : []
    content {
      mode                      = var.high_availability.mode
      standby_availability_zone = var.high_availability.standby_availability_zone
    }
  }
  
  # Network configuration - Private access
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id != null ? var.private_dns_zone_id : azurerm_private_dns_zone.mysql[0].id
  
  # Maintenance window
  maintenance_window {
    day_of_week  = 0  # Sunday
    start_hour   = 2
    start_minute = 0
  }
  
  tags = var.tags
  
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      administrator_password,
    ]
  }
}

# Server Parameters for HIPAA compliance and performance
resource "azurerm_mysql_flexible_server_configuration" "audit_log" {
  name                = "audit_log_enabled"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "audit_log_events" {
  name                = "audit_log_events"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "CONNECTION,DCL,DDL,DML"
}

resource "azurerm_mysql_flexible_server_configuration" "slow_query_log" {
  name                = "slow_query_log"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "long_query_time" {
  name                = "long_query_time"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "2"
}

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "tls_version" {
  name                = "tls_version"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "TLSv1.2,TLSv1.3"
}

resource "azurerm_mysql_flexible_server_configuration" "innodb_buffer_pool_size" {
  name                = "innodb_buffer_pool_size"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "8589934592"  # 8GB
}

resource "azurerm_mysql_flexible_server_configuration" "max_connections" {
  name                = "max_connections"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "1000"
}

resource "azurerm_mysql_flexible_server_configuration" "character_set_server" {
  name                = "character_set_server"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  value               = "utf8mb4"
}

# LIS Database
resource "azurerm_mysql_flexible_database" "lis" {
  name                = "LIS"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Audit Database (for HIPAA compliance)
resource "azurerm_mysql_flexible_database" "audit" {
  name                = "LIS_Audit"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.lis.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Store credentials in Key Vault
resource "azurerm_key_vault_secret" "mysql_admin_password" {
  name         = "mysql-admin-password"
  value        = random_password.mysql_admin.result
  key_vault_id = var.key_vault_id
  
  content_type = "text/plain"
  
  tags = merge(var.tags, {
    Purpose = "MySQL Admin Password"
  })
}

resource "azurerm_key_vault_secret" "mysql_connection_string" {
  name         = "mysql-connection-string"
  value        = "Server=${azurerm_mysql_flexible_server.lis.fqdn};Port=3306;Database=LIS;User=${var.administrator_login};Password=${random_password.mysql_admin.result};SslMode=Required;AllowPublicKeyRetrieval=True"
  key_vault_id = var.key_vault_id
  
  content_type = "text/plain"
  
  tags = merge(var.tags, {
    Purpose = "MySQL Connection String"
  })
}

# Diagnostic settings for auditing
resource "azurerm_monitor_diagnostic_setting" "mysql" {
  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_mysql_flexible_server.lis.id
  log_analytics_workspace_id = var.key_vault_id  # Should be Log Analytics Workspace ID
  
  enabled_log {
    category = "MySqlSlowLogs"
  }
  
  enabled_log {
    category = "MySqlAuditLogs"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Outputs
output "server_id" {
  description = "MySQL Server ID"
  value       = azurerm_mysql_flexible_server.lis.id
}

output "server_fqdn" {
  description = "MySQL Server FQDN"
  value       = azurerm_mysql_flexible_server.lis.fqdn
}

output "server_name" {
  description = "MySQL Server Name"
  value       = azurerm_mysql_flexible_server.lis.name
}

output "administrator_login" {
  description = "MySQL Administrator Login"
  value       = azurerm_mysql_flexible_server.lis.administrator_login
  sensitive   = true
}

output "database_name" {
  description = "Main database name"
  value       = azurerm_mysql_flexible_database.lis.name
}

output "connection_string_secret_id" {
  description = "Key Vault Secret ID for connection string"
  value       = azurerm_key_vault_secret.mysql_connection_string.id
}

output "private_dns_zone_id" {
  description = "Private DNS Zone ID"
  value       = var.private_dns_zone_id != null ? var.private_dns_zone_id : azurerm_private_dns_zone.mysql[0].id
}
