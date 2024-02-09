resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "this" {
  name = azurerm_resource_group.this.name
}

resource "azurerm_firewall_policy" "name" {
  name                     = var.name
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"
}
