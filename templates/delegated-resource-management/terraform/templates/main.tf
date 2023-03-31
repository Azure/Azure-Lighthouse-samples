
resource "azurerm_lighthouse_definition" "definition" {
  name               = var.mspoffername
  description        = var.mspofferdescription
  managing_tenant_id = var.managedbytenantid
  scope              = var.scope

  authorization {
    principal_id           = var.principal_id
    role_definition_id     = var.role_definition_id
    principal_display_name = var.principal_display_name
  }
}

resource "azurerm_lighthouse_assignment" "assignment" {
  scope                    = var.scope
  lighthouse_definition_id = azurerm_lighthouse_definition.definition.id
}