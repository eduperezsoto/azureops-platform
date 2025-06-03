terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.31.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true  
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}


####### RESOURCE GROUP #######
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Owner = var.owner_tag
  }
}


####### KEY VAULT #######
data "azurerm_key_vault" "kv_base" {
  name                = "kv-base"
  resource_group_name = var.infra_base_resource_group_name
}


#######  Azure Policy #######
module "azure_policy" {
  source         = "./modules/policy"
  resource_group_id = azurerm_resource_group.rg.id
}


####### Log analytics #######
module "log_analytics" {
  source = "./modules/monitor/log-analytics"
  app_name = var.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  owner_tag = var.owner_tag
}


####### Application insights #######
module "application_insights" {
  source = "./modules/monitor/application-insights"
  app_name = var.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  owner_tag = var.owner_tag
  subscription_id = data.azurerm_subscription.current.subscription_id
  workspace_id = module.log_analytics.workspace_id
}


####### App service plan
module "appservice_plan" {
  source = "./modules/app/plan"
  app_name = var.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku_name = var.sku_name
  os_type = var.os_type
  owner_tag = var.owner_tag
}


####### App service
module "app_service" {
  source = "./modules/app/service"
  app_name = var.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  infra_base_resource_group_name = var.infra_base_resource_group_name
  service_plan_id = module.appservice_plan.service_plan_id
  key_vault_uri = data.azurerm_key_vault.kv_base.vault_uri
  instrumentation_key = module.application_insights.instrumentation_key
  connection_string = module.application_insights.connection_string
  owner_tag = var.owner_tag
}






