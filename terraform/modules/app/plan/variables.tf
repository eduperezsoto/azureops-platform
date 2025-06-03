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

variable "sku_name" {
  description = "The SKU for the plan."
  type        = string
  default     = "B1"
}

variable "os_type" {
  description = "The O/S type for the App Services to be hosted in this plan."
  type        = string
  default     = "Linux"
}

variable "owner_tag" {
  description = "Value for the Owner tag on resources"
  type        = string
}


