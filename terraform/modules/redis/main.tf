# MedinovAI LIS Infrastructure - Redis Module
# Terraform module for Azure Cache for Redis
# High-performance caching with HIPAA-compliant security

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

variable "redis_name" {
  type        = string
  description = "Redis cache name"
  default     = "medinovai-lis-redis"
}

variable "environment" {
  type        = string
  description = "Environment (development, staging, production)"
  default     = "production"
}

variable "sku" {
  type = object({
    name     = string
    family   = string
    capacity = number
  })
  description = "Redis SKU configuration"
  default = {
    name     = "Premium"
    family   = "P"
    capacity = 1  # P1: 6GB cache, 7500 connections
  }
}

variable "redis_version" {
  type        = string
  description = "Redis version"
  default     = "6"
}

variable "enable_non_ssl_port" {
  type        = bool
  description = "Enable non-SSL port (NOT recommended for healthcare)"
  default     = false
}

variable "minimum_tls_version" {
  type        = string
  description = "Minimum TLS version"
  default     = "1.2"
}

variable "shard_count" {
  type        = number
  description = "Number of shards (for Premium tier clustering)"
  default     = 0  # 0 = no clustering
}

variable "replicas_per_master" {
  type        = number
  description = "Number of replicas per master (for Premium tier)"
  default     = 1
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint"
  default     = null
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault ID for storing secrets"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostics"
  default     = null
}

variable "redis_configuration" {
  type = object({
    maxmemory_policy              = string
    maxmemory_reserved            = number
    maxfragmentationmemory_reserved = number
    notify_keyspace_events        = string
    aof_backup_enabled            = bool
    rdb_backup_enabled            = bool
    rdb_backup_frequency          = number
    rdb_storage_connection_string = string
  })
  description = "Redis configuration"
  default = {
    maxmemory_policy              = "allkeys-lru"
    maxmemory_reserved            = 200
    maxfragmentationmemory_reserved = 200
    notify_keyspace_events        = ""
    aof_backup_enabled            = false
    rdb_backup_enabled            = true
    rdb_backup_frequency          = 60
    rdb_storage_connection_string = ""
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    Project     = "MedinovAI-LIS"
    ManagedBy   = "Terraform"
    Compliance  = "HIPAA"
    DataClass   = "Cache"
  }
}

# Private DNS Zone for Redis
resource "azurerm_private_dns_zone" "redis" {
  count               = var.subnet_id != null ? 1 : 0
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "lis" {
  name                = var.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # SKU configuration
  capacity = var.sku.capacity
  family   = var.sku.family
  sku_name = var.sku.name
  
  # Security configuration
  enable_non_ssl_port = var.enable_non_ssl_port
  minimum_tls_version = var.minimum_tls_version
  
  # Network configuration
  public_network_access_enabled = var.subnet_id == null
  
  # Redis version
  redis_version = var.redis_version
  
  # Clustering (Premium tier only)
  shard_count         = var.sku.name == "Premium" ? var.shard_count : null
  replicas_per_master = var.sku.name == "Premium" ? var.replicas_per_master : null
  
  # Availability zones (Premium tier only)
  zones = var.sku.name == "Premium" ? ["1", "2", "3"] : null
  
  # Redis configuration
  redis_configuration {
    maxmemory_policy                  = var.redis_configuration.maxmemory_policy
    maxmemory_reserved                = var.redis_configuration.maxmemory_reserved
    maxfragmentationmemory_reserved   = var.redis_configuration.maxfragmentationmemory_reserved
    notify_keyspace_events            = var.redis_configuration.notify_keyspace_events
    
    # AOF persistence (Premium tier)
    aof_backup_enabled = var.sku.name == "Premium" ? var.redis_configuration.aof_backup_enabled : null
    
    # RDB persistence (Premium tier)
    rdb_backup_enabled            = var.sku.name == "Premium" ? var.redis_configuration.rdb_backup_enabled : null
    rdb_backup_frequency          = var.sku.name == "Premium" && var.redis_configuration.rdb_backup_enabled ? var.redis_configuration.rdb_backup_frequency : null
    rdb_storage_connection_string = var.sku.name == "Premium" && var.redis_configuration.rdb_backup_enabled && var.redis_configuration.rdb_storage_connection_string != "" ? var.redis_configuration.rdb_storage_connection_string : null
  }
  
  # Patch schedule
  patch_schedule {
    day_of_week        = "Sunday"
    start_hour_utc     = 2
    maintenance_window = "PT5H"
  }
  
  tags = var.tags
  
  lifecycle {
    prevent_destroy = true
  }
}

# Private Endpoint for Redis
resource "azurerm_private_endpoint" "redis" {
  count               = var.subnet_id != null ? 1 : 0
  name                = "${var.redis_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "${var.redis_name}-psc"
    private_connection_resource_id = azurerm_redis_cache.lis.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name                 = "redis-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis[0].id]
  }
  
  tags = var.tags
}

# Firewall rules (when not using private endpoint)
resource "azurerm_redis_firewall_rule" "allow_azure" {
  count               = var.subnet_id == null ? 1 : 0
  name                = "AllowAzureServices"
  redis_cache_name    = azurerm_redis_cache.lis.name
  resource_group_name = var.resource_group_name
  start_ip            = "0.0.0.0"
  end_ip              = "0.0.0.0"
}

# Store credentials in Key Vault
resource "azurerm_key_vault_secret" "redis_primary_key" {
  name         = "redis-primary-key"
  value        = azurerm_redis_cache.lis.primary_access_key
  key_vault_id = var.key_vault_id
  
  content_type = "text/plain"
  
  tags = merge(var.tags, {
    Purpose = "Redis Primary Access Key"
  })
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  value        = azurerm_redis_cache.lis.primary_connection_string
  key_vault_id = var.key_vault_id
  
  content_type = "text/plain"
  
  tags = merge(var.tags, {
    Purpose = "Redis Connection String"
  })
}

# Application-friendly connection string (StackExchange.Redis format)
resource "azurerm_key_vault_secret" "redis_stackexchange_connection" {
  name         = "redis-stackexchange-connection"
  value        = "${azurerm_redis_cache.lis.hostname}:${azurerm_redis_cache.lis.ssl_port},password=${azurerm_redis_cache.lis.primary_access_key},ssl=True,abortConnect=False,connectTimeout=10000,syncTimeout=10000"
  key_vault_id = var.key_vault_id
  
  content_type = "text/plain"
  
  tags = merge(var.tags, {
    Purpose = "Redis StackExchange Connection String"
  })
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "redis" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.redis_name}-diagnostics"
  target_resource_id         = azurerm_redis_cache.lis.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  metric {
    category = "AllMetrics"
  }
}

# Outputs
output "redis_id" {
  description = "Redis Cache ID"
  value       = azurerm_redis_cache.lis.id
}

output "redis_hostname" {
  description = "Redis Cache hostname"
  value       = azurerm_redis_cache.lis.hostname
}

output "redis_ssl_port" {
  description = "Redis SSL port"
  value       = azurerm_redis_cache.lis.ssl_port
}

output "redis_primary_key" {
  description = "Redis primary access key"
  value       = azurerm_redis_cache.lis.primary_access_key
  sensitive   = true
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = azurerm_redis_cache.lis.primary_connection_string
  sensitive   = true
}

output "connection_string_secret_id" {
  description = "Key Vault Secret ID for connection string"
  value       = azurerm_key_vault_secret.redis_connection_string.id
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address"
  value       = var.subnet_id != null ? azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address : null
}
