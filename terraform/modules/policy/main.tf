# Custom policy: Require owner tag
resource "azurerm_policy_definition" "require_owner_tag" {
  name         = "Require-Owner-Tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Requerir etiqueta Owner en recursos"
  description  = "Niega creación de recursos que no tengan la etiqueta especificada en 'tagName'."
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
  policy_definition_id = azurerm_policy_definition.require_owner_tag.id

  parameters = <<PARAMS
{
  "tagName": {
    "value": "Owner"
  }
}
PARAMS
}


# Custom policy: Allowed Locations
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "Allowed-Locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Only allowed locations for TFM RG"
  description  = "Solo regiones westeurope y northeurope."
  policy_rule  = file("${path.module}/../../../azure-policies/allowed_locations.json")
  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "type": "Array",
    "metadata": {
      "displayName": "Allowed Locations",
      "description": "Lista de regiones autorizadas"
    }
  }
}
PARAMETERS
}

resource "azurerm_resource_group_policy_assignment" "assign_rg_allowed_locations" {
  name                 = "Allowed Locations"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.allowed_locations.id

  parameters = <<PARAMS
{
  "allowedLocations": {
    "value": [ "westeurope", "northeurope" ]
  }
}
PARAMS
}