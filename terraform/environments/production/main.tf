# MedinovAI LIS - Production Environment
# Terraform configuration for production infrastructure

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
  
  backend "azurerm" {
    resource_group_name  = "medinovai-terraform-state"
    storage_account_name = "medinovaiterraform"
    container_name       = "tfstate"
    key                  = "production.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

# Local variables
locals {
  environment = "production"
  location    = "eastus2"
  
  tags = {
    Project     = "MedinovAI-LIS"
    Environment = local.environment
    ManagedBy   = "Terraform"
    Compliance  = "HIPAA,ISO13485"
    CostCenter  = "LIS-Platform"
  }
}

# Kubernetes Cluster
module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"
  
  cluster_name        = "medinovai-lis-${local.environment}"
  resource_group_name = "medinovai-lis-${local.environment}-rg"
  location            = local.location
  environment         = local.environment
  kubernetes_version  = "1.28"
  
  node_pools = {
    system = {
      vm_size             = "Standard_D4s_v5"
      node_count          = 3
      min_count           = 3
      max_count           = 5
      max_pods            = 110
      os_disk_size_gb     = 128
      os_disk_type        = "Managed"
      enable_auto_scaling = true
      availability_zones  = ["1", "2", "3"]
      node_labels         = { "node-type" = "system" }
      node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]
    }
    healthcare = {
      vm_size             = "Standard_D8s_v5"
      node_count          = 5
      min_count           = 5
      max_count           = 30
      max_pods            = 110
      os_disk_size_gb     = 256
      os_disk_type        = "Managed"
      enable_auto_scaling = true
      availability_zones  = ["1", "2", "3"]
      node_labels         = { "node-type" = "healthcare" }
      node_taints         = []
    }
  }
  
  tags = local.tags
}

# Database
module "database" {
  source = "../../modules/database"
  
  resource_group_name = module.kubernetes_cluster.cluster_name
  location            = local.location
  server_name         = "medinovai-lis-${local.environment}-mysql"
  environment         = local.environment
  
  sku_name     = "GP_Standard_D8ds_v4"
  mysql_version = "8.0.21"
  
  storage_size_gb       = 512
  storage_iops          = 2000
  backup_retention_days = 35
  geo_redundant_backup  = true
  
  high_availability = {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
  
  delegated_subnet_id = module.kubernetes_cluster.cluster_id  # Would be actual subnet ID
  key_vault_id        = module.kubernetes_cluster.key_vault_id
  
  tags = local.tags
  
  depends_on = [module.kubernetes_cluster]
}

# Redis Cache
module "redis" {
  source = "../../modules/redis"
  
  resource_group_name = module.kubernetes_cluster.cluster_name
  location            = local.location
  redis_name          = "medinovai-lis-${local.environment}-redis"
  environment         = local.environment
  
  sku = {
    name     = "Premium"
    family   = "P"
    capacity = 2
  }
  
  redis_version       = "6"
  minimum_tls_version = "1.2"
  shard_count         = 2
  replicas_per_master = 1
  
  key_vault_id               = module.kubernetes_cluster.key_vault_id
  log_analytics_workspace_id = module.kubernetes_cluster.log_analytics_workspace_id
  
  tags = local.tags
  
  depends_on = [module.kubernetes_cluster]
}

# Outputs
output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = module.kubernetes_cluster.cluster_name
}

output "cluster_fqdn" {
  description = "Kubernetes cluster FQDN"
  value       = module.kubernetes_cluster.cluster_fqdn
}

output "acr_login_server" {
  description = "Container registry login server"
  value       = module.kubernetes_cluster.acr_login_server
}

output "mysql_fqdn" {
  description = "MySQL server FQDN"
  value       = module.database.server_fqdn
}

output "redis_hostname" {
  description = "Redis hostname"
  value       = module.redis.redis_hostname
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.kubernetes_cluster.key_vault_uri
}
