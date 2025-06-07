# Custom policy: Require tag
resource "azurerm_policy_definition" "require_tag" {
  name         = "Require-Tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Tag"
  description  = "Denies creation or updating of resources that do not have the specified label."
  policy_rule  = file("${path.module}/../../../azure-policies/require_tags.json")
  parameters = <<PARAMS
{
  "tagName": {
    "type": "String",
    "defaultValue": "Owner",
    "metadata": {
      "displayName": "Tag Name",
      "description": "Name of the mandatory label"
    }
  }
}
PARAMS
}

resource "azurerm_resource_group_policy_assignment" "assign_require_owner_tag" {
  name                 = "Require Owner Tag"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.require_tag.id

  parameters = <<PARAMS
{
  "tagName": {
    "value": "Owner"
  }
}
PARAMS
}


# Builtin policy: Allowed Locations
resource "azurerm_resource_group_policy_assignment" "assign_rg_allowed_locations" {
  name                 = "Allowed Locations"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  parameters = <<PARAMS
{
  "listOfAllowedLocations": {
    "value": [ "westeurope", "northeurope" ]
  }
}
PARAMS
}


# ISO/IEC 27001:2013
resource "azurerm_resource_group_policy_assignment" "iso27001_initiative" {
  name                 = "ISO 27001 Initiative"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2"
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}


# CIS Azure Foundations Bencharmark v2.0.0 Initiative
resource "azurerm_resource_group_policy_assignment" "cis_benchamark_initiative" {
  name                 = "CIS Azure Foundations Bencharmark v2.0.0 Initiative"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/06f19060-9e68-4070-92ca-f15cc126059e"
  location             = var.location

  parameters = <<PARAMS
{
  "maximumDaysToRotate-d8cf8476-a2ec-4916-896e-992351803c44": {
    "value": 90
  }
}
PARAMS
}
