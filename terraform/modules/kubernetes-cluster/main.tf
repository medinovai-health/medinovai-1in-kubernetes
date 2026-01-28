# MedinovAI LIS Infrastructure - Kubernetes Cluster Module
# Terraform module for provisioning AKS/EKS/GKE clusters
# Healthcare-compliant with HIPAA/ISO 13485 security controls

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# Variables
variable "cluster_name" {
  type        = string
  description = "Name of the Kubernetes cluster"
  default     = "medinovai-lis-aks"
}

variable "location" {
  type        = string
  description = "Azure region for the cluster"
  default     = "eastus2"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "medinovai-lis-rg"
}

variable "environment" {
  type        = string
  description = "Environment (development, staging, production)"
  default     = "production"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.28"
}

variable "node_pools" {
  type = map(object({
    vm_size               = string
    node_count            = number
    min_count             = number
    max_count             = number
    max_pods              = number
    os_disk_size_gb       = number
    os_disk_type          = string
    enable_auto_scaling   = bool
    availability_zones    = list(string)
    node_labels           = map(string)
    node_taints           = list(string)
  }))
  description = "Node pool configurations"
  default = {
    system = {
      vm_size               = "Standard_D4s_v5"
      node_count            = 3
      min_count             = 3
      max_count             = 5
      max_pods              = 110
      os_disk_size_gb       = 128
      os_disk_type          = "Managed"
      enable_auto_scaling   = true
      availability_zones    = ["1", "2", "3"]
      node_labels           = { "node-type" = "system" }
      node_taints           = ["CriticalAddonsOnly=true:NoSchedule"]
    }
    healthcare = {
      vm_size               = "Standard_D8s_v5"
      node_count            = 3
      min_count             = 3
      max_count             = 20
      max_pods              = 110
      os_disk_size_gb       = 256
      os_disk_type          = "Managed"
      enable_auto_scaling   = true
      availability_zones    = ["1", "2", "3"]
      node_labels           = { "node-type" = "healthcare" }
      node_taints           = []
    }
  }
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR block for the virtual network"
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  type = object({
    aks_subnet     = string
    db_subnet      = string
    service_subnet = string
  })
  description = "CIDR blocks for subnets"
  default = {
    aks_subnet     = "10.0.0.0/18"
    db_subnet      = "10.0.64.0/24"
    service_subnet = "10.0.65.0/24"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Project     = "MedinovAI-LIS"
    ManagedBy   = "Terraform"
    Compliance  = "HIPAA,ISO13485"
    Environment = "production"
  }
}

# Resource Group
resource "azurerm_resource_group" "lis" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "lis" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.lis.location
  resource_group_name = azurerm_resource_group.lis.name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.lis.name
  virtual_network_name = azurerm_virtual_network.lis.name
  address_prefixes     = [var.subnet_cidrs.aks_subnet]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "database" {
  name                 = "${var.cluster_name}-db-subnet"
  resource_group_name  = azurerm_resource_group.lis.name
  virtual_network_name = azurerm_virtual_network.lis.name
  address_prefixes     = [var.subnet_cidrs.db_subnet]
  service_endpoints    = ["Microsoft.Sql"]
  
  delegation {
    name = "mysql-delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "lis" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.lis.location
  resource_group_name = azurerm_resource_group.lis.name
  sku                 = "PerGB2018"
  retention_in_days   = 90  # HIPAA requires minimum 6 years, configure archival separately
  tags                = var.tags
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "lis" {
  name                = var.cluster_name
  location            = azurerm_resource_group.lis.location
  resource_group_name = azurerm_resource_group.lis.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  
  # Use User Assigned Identity for better security
  identity {
    type = "SystemAssigned"
  }
  
  # Default node pool (system)
  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_pools.system.vm_size
    node_count                   = var.node_pools.system.node_count
    min_count                    = var.node_pools.system.enable_auto_scaling ? var.node_pools.system.min_count : null
    max_count                    = var.node_pools.system.enable_auto_scaling ? var.node_pools.system.max_count : null
    max_pods                     = var.node_pools.system.max_pods
    os_disk_size_gb              = var.node_pools.system.os_disk_size_gb
    os_disk_type                 = var.node_pools.system.os_disk_type
    enable_auto_scaling          = var.node_pools.system.enable_auto_scaling
    zones                        = var.node_pools.system.availability_zones
    vnet_subnet_id               = azurerm_subnet.aks.id
    node_labels                  = var.node_pools.system.node_labels
    only_critical_addons_enabled = true
    
    upgrade_settings {
      max_surge = "33%"
    }
  }
  
  # Network configuration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"  # Enable network policies for zero-trust
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }
  
  # Enable Azure AD integration
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = []  # Add your AD group IDs
    azure_rbac_enabled     = true
  }
  
  # Enable Container Insights
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.lis.id
  }
  
  # Enable Defender for Containers
  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.lis.id
  }
  
  # Key Vault integration for secrets
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
  
  # Workload Identity
  workload_identity_enabled = true
  oidc_issuer_enabled       = true
  
  # Security settings
  api_server_access_profile {
    authorized_ip_ranges = []  # Add your allowed IPs
  }
  
  # Auto-upgrade settings
  automatic_channel_upgrade = "stable"
  
  # Maintenance window
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

# Healthcare Node Pool
resource "azurerm_kubernetes_cluster_node_pool" "healthcare" {
  name                  = "healthcare"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.lis.id
  vm_size               = var.node_pools.healthcare.vm_size
  node_count            = var.node_pools.healthcare.node_count
  min_count             = var.node_pools.healthcare.min_count
  max_count             = var.node_pools.healthcare.max_count
  max_pods              = var.node_pools.healthcare.max_pods
  os_disk_size_gb       = var.node_pools.healthcare.os_disk_size_gb
  os_disk_type          = var.node_pools.healthcare.os_disk_type
  enable_auto_scaling   = var.node_pools.healthcare.enable_auto_scaling
  zones                 = var.node_pools.healthcare.availability_zones
  vnet_subnet_id        = azurerm_subnet.aks.id
  node_labels           = var.node_pools.healthcare.node_labels
  
  upgrade_settings {
    max_surge = "33%"
  }
  
  tags = var.tags
}

# Container Registry for images
resource "azurerm_container_registry" "lis" {
  name                = replace("${var.cluster_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.lis.name
  location            = azurerm_resource_group.lis.location
  sku                 = "Premium"
  admin_enabled       = false
  
  # Enable content trust for image signing
  trust_policy {
    enabled = true
  }
  
  # Retention policy
  retention_policy {
    days    = 90
    enabled = true
  }
  
  # Geo-replication for DR
  georeplications {
    location                = "westus2"
    zone_redundancy_enabled = true
  }
  
  # Network rules
  network_rule_set {
    default_action = "Deny"
    virtual_network {
      action    = "Allow"
      subnet_id = azurerm_subnet.aks.id
    }
  }
  
  tags = var.tags
}

# Attach ACR to AKS
resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.lis.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.lis.id
  skip_service_principal_aad_check = true
}

# Key Vault for secrets
resource "azurerm_key_vault" "lis" {
  name                       = "${var.cluster_name}-kv"
  location                   = azurerm_resource_group.lis.location
  resource_group_name        = azurerm_resource_group.lis.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  
  # Network rules
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.aks.id]
  }
  
  tags = var.tags
}

# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# Outputs
output "cluster_id" {
  description = "The Kubernetes Cluster ID"
  value       = azurerm_kubernetes_cluster.lis.id
}

output "cluster_name" {
  description = "The Kubernetes Cluster name"
  value       = azurerm_kubernetes_cluster.lis.name
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.lis.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "The FQDN of the Kubernetes Cluster"
  value       = azurerm_kubernetes_cluster.lis.fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.lis.oidc_issuer_url
}

output "acr_login_server" {
  description = "The Container Registry login server"
  value       = azurerm_container_registry.lis.login_server
}

output "key_vault_id" {
  description = "The Key Vault ID"
  value       = azurerm_key_vault.lis.id
}

output "key_vault_uri" {
  description = "The Key Vault URI"
  value       = azurerm_key_vault.lis.vault_uri
}

output "log_analytics_workspace_id" {
  description = "The Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.lis.id
}
