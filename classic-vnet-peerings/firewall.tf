resource "azurerm_firewall" "this" {
  name                = "testfirewall"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  # TODO: this `private_ip_ranges` seems to be sufficient just in the `azurerm_firewall_policy` resource.
  #private_ip_ranges = var.disable_snat_ip_range

  firewall_policy_id = azurerm_firewall_policy.firewallpolicy.id

  ip_configuration {
    name      = "configuration"
    subnet_id = lookup(module.networkhub.vnet_subnets_name_id, "AzureFirewallSubnet")
    #public_ip_address_id = azurerm_public_ip.this.id
  }

  management_ip_configuration {
    name                 = "management"
    subnet_id            = lookup(module.networkhub.vnet_subnets_name_id, "AzureFirewallManagementSubnet")
    public_ip_address_id = azurerm_public_ip.management_public_ip.id
  }
}

resource "azurerm_firewall_policy" "firewallpolicy" {
  name                     = "firewallpolicy"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"
  private_ip_ranges        = var.disable_snat_ip_range

}

resource "azurerm_firewall_policy_rule_collection_group" "example" {
  name               = "example-fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.firewallpolicy.id
  priority           = 500


  network_rule_collection {
    name     = "network_rule_collection1"
    priority = 400
    action   = "Allow"
    rule {
      name                  = "network_rule_collection1_rule1"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.1.0.0/19"]
      destination_addresses = ["192.168.0.0/19"]
      destination_ports     = ["22-80", "1000-8888"]
    }
  }

}

resource "azurerm_public_ip" "management_public_ip" {
  name                = "management-public-ip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
