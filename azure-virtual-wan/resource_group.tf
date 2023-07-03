resource "azurerm_resource_group" "this" {
  name     = "nat-rg"
  location = var.region
}
