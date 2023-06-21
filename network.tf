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

# Create a routing table for networkspoke1
resource "azurerm_route_table" "this" {
  name                = "spoke1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}
# Add a default route that points to the firewall
resource "azurerm_route" "this" {
  name                   = "default"
  resource_group_name    = azurerm_resource_group.this.name
  route_table_name       = azurerm_route_table.this.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

# Association of networkspoke1 subnet to the route table
resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      =lookup(module.networkspoke1.vnet_subnets_name_id, "subnet0")
  route_table_id = azurerm_route_table.this.id
}

#Vnet peering for networkhub with networkspoke1
resource "azurerm_virtual_network_peering" "hub2spoke1" {
  name                      = "hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = "hub"
  remote_virtual_network_id = module.networkspoke1.vnet_id
}

#Vnet peering for networkspoke1 with networkhub
resource "azurerm_virtual_network_peering" "spoke12hub" {
  name                      = "networkspoke1"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = "spoke1"
  remote_virtual_network_id = module.networkhub.vnet_id
}

#Vnet peering for networkhub with globalhub
resource "azurerm_virtual_network_peering" "hub2global" {
  name                      = "global"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = "hub"
  remote_virtual_network_id = module.globalhub.vnet_id
}

#Vnet peering for globalhub with networkhub
resource "azurerm_virtual_network_peering" "global2hub" {
  name                      = "hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = "global"
  remote_virtual_network_id = module.networkhub.vnet_id
}

