variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
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

variable "owner_tag" {
  description = "Value for the Owner tag on resources"
  type        = string
  default     = "eduperezsoto"
}

variable "app_sku_name" {
  description = "The SKU for the plan"
  type        = string
  default     = "B1"
}

variable "os_type" {
  description = "The O/S type for the App Services to be hosted in this plan"
  type        = string
  default     = "Linux"
}

variable "app_env" {
  description = "Enviroment of the app"
  type        = string
  default     = "production"
}

variable "app_python_version" {
  description = "Python version of the app"
  type        = string
  default     = "3.13"
}
