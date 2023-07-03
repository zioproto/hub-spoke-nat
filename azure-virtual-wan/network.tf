resource "azurerm_virtual_wan" "vwan" {
  name                = "vwan"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "Standard"
}

resource "azurerm_virtual_hub" "vhub" {
  name                = "vhub"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  address_prefix      = "172.16.0.0/16"
}

resource "azurerm_virtual_hub_connection" "networkspoke1_to_hub" {
  virtual_hub_id            = azurerm_virtual_hub.vhub.id
  remote_virtual_network_id = module.networkspoke1.vnet_id
  name                      = "networkspoke1_to_hub"
}

resource "azurerm_virtual_hub_connection" "networkhub_to_hub" {
  virtual_hub_id            = azurerm_virtual_hub.vhub.id
  remote_virtual_network_id = module.networkhub.vnet_id
  name                      = "networkhub_to_hub"
}

#Vnet peering for networkhub with globalhub
resource "azurerm_virtual_network_peering" "hub2global" {
  name                      = "global"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = "hub"
  remote_virtual_network_id = module.globalhub.vnet_id
  allow_forwarded_traffic = true
}

#Vnet peering for globalhub with networkhub
resource "azurerm_virtual_network_peering" "global2hub" {
  name                      = "hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = "global"
  remote_virtual_network_id = module.networkhub.vnet_id
  allow_forwarded_traffic = true

}

module "networkspoke1" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"

  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    subnet0 = {
      address_prefixes = ["10.1.0.0/19"]
    }
  }
  virtual_network_address_space = ["10.1.0.0/19"]
  virtual_network_location      = var.region
  virtual_network_name          = "spoke1"
}

module "networkhub" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"


  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    AzureFirewallManagementSubnet = {
      address_prefixes = ["10.129.0.0/24"]
    },
    AzureFirewallSubnet = {
      address_prefixes = ["10.129.1.0/24"]
    },
    subnet0 = {
      address_prefixes = ["10.129.2.0/24"]
    }
  }
  virtual_network_address_space = ["10.129.0.0/19"]
  virtual_network_location      = var.region
  virtual_network_name          = "hub"
}

module "globalhub" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"


  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    subnet0 = {
      address_prefixes = ["192.168.0.0/19"]
    }
  }
  virtual_network_address_space = ["192.168.0.0/19"]
  virtual_network_location      = var.region
  virtual_network_name          = "global"
}




