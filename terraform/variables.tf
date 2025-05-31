variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "infra_base_resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-infra-base"
}

variable "app_name" {
  description = "Name for the App Service"
  type        = string
}

variable "key_vault_name" {
  description = "Name for the Key Vault"
  type        = string
}

variable "my_secret_value" {
  description = "Value for the demo secret MY_SECRET"
  type        = string
  default     = "DevSecretValue"
}

variable "expiry_date" {
  description = "Expiry date"
  type        = string
  default     = "2025-12-31T23:59:59Z"
}

variable "owner_tag" {
  description = "Value for the Owner tag on resources"
  type        = string
}
