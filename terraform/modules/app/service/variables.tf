variable "app_name" {
  description = "Name for the App Service"
  type        = string
}

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

variable "service_plan_id" {
  description = "Id of the service plan to use"
  type        = string
}

variable "owner_tag" {
  description = "Value for the Owner tag on resources"
  type        = string
}

variable "key_vault_uri" {
  description = "Uri of the key vault to be used in the app"
  type        = string
}

variable "instrumentation_key" {
  description = "Instrumentation key"
  type = string
}

variable "connection_string" {
  description = "Connection String"
  type = string
}

variable "workspace_id" {
  description = "Id of the log analytics workspace"
  type        = string
}
