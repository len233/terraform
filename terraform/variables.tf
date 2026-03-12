# Variables definition file

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-terraform-cloud"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "France Central"
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "tfcloud"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique)"
  type        = string
  default     = "tfcloudstorage2026"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "db_admin_username" {
  description = "Database administrator username"
  type        = string
  default     = "dbadmin"
}

variable "db_admin_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}
