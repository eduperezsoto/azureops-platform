variable "resource_group_id" {
  description = "Id of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}