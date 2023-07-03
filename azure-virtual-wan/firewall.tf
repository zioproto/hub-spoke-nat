resource "azurerm_firewall" "this" {
  name                = "testfirewall"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Standard"

  # TODO: this `private_ip_ranges` seems to be sufficient just in the `azurerm_firewall_policy` resource.
  #private_ip_ranges = var.disable_snat_ip_range

  firewall_policy_id = azurerm_firewall_policy.firewallpolicy.id

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.vhub.id
    public_ip_count = 1
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
      source_addresses      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      destination_addresses = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
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
