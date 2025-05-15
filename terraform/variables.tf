variable "rg_name" {
  type        = string
  description = "Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "West Europe"
}

variable "prefix" {
  type        = string
  description = "Prefix for naming"
}

variable "app_name" {
  type        = string
  description = "App Service name"
}

variable "my_secret_value" {
  type        = string
  description = "Initial secret value"
}
