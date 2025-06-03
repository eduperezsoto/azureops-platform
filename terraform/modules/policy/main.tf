# Custom policy: Require tag
resource "azurerm_policy_definition" "require_tag" {
  name         = "Require-Tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Tag"
  description  = "Niega creación o actualizacion de recursos que no tengan la etiqueta especificada."
  policy_rule  = file("${path.module}/../../../azure-policies/require_tags.json")
  parameters = <<PARAMS
{
  "tagName": {
    "type": "String",
    "defaultValue": "Owner",
    "metadata": {
      "displayName": "Tag Name",
      "description": "Nombre de la etiqueta obligatoria en cada recurso"
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