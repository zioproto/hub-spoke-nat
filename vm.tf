
locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
echo "Execute your super awesome commands here!"
sudo sed -i "s/#Port 22/Port 2222/" /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker azureuser
sudo apt-get -y install build-essential jq
CUSTOM_DATA
}

resource "azurerm_network_interface" "main" {
  name                = "vm-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = lookup(module.networkspoke1.vnet_subnets_name_id, "subnet0")
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "server" {
  name                = "vm-server-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "testconfiguration2"
    subnet_id                     = lookup(module.globalhub.vnet_subnets_name_id, "subnet0")
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "myubuntuvm"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_D8_v4"

  boot_diagnostics {
     enabled = true
     storage_uri = ""
  }

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "azureuser"
    admin_password = "Password1234!"
    custom_data    = base64encode(local.custom_data)
  }


  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpux1Um/iKn8irWebhYGcuAvQInAG2sbI+Ac853XK1TdQyHuMPVeFs4JZREeSXIFFoY3yqrmSJTfeAkIvS1+d0EXwgC/0Nc6qCgFt4JwRoqXwfbsPAzZLOuiXvj+ssHp2aFxA8r+N3GuG5zrzxiC6w5ClwJMtXnap2t3cq/9V4nuKxCFIBjnT8dvoNMOOA3JZ0Cun+VaQrnocee9qyDl1AwkUkT01qSe6HovZUUE0vR1nVSrBFayx0TAK+fjPPfjcm0U68krM4N2puN7YFydgcTumSZL+/8Mr2P0zkB4Axc/BaA12dmmu0bW0IK4L7i6g648cmoNbM0/rHokfQINUnw5Gx77pS32udVGFCSfPcvILk9ePrXEqAofFV0AXGa9Bs1GmpRsNM0mTzmXHjdVr6MostJhvfUoR4pKKKQKVW5pXjvimE5/IdGQ6pCBjhQHyvOhOBpXJPwBHwvi6c97a0kYzM/ETeYUa4btNKdxVzEzKP9b+VxR04bgk46brx6SU= saverioproto@Saverios-MacBook-Pro.local"
    }
  }
}


resource "azurerm_virtual_machine" "server" {
  name                  = "ubuntuserver"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.server.id]
  vm_size               = "Standard_D8_v4"

  boot_diagnostics {
     enabled = true
     storage_uri = ""
  }

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdiskserver"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "azureuser"
    admin_password = "Password1234!"
    custom_data    = base64encode(local.custom_data)
  }


  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpux1Um/iKn8irWebhYGcuAvQInAG2sbI+Ac853XK1TdQyHuMPVeFs4JZREeSXIFFoY3yqrmSJTfeAkIvS1+d0EXwgC/0Nc6qCgFt4JwRoqXwfbsPAzZLOuiXvj+ssHp2aFxA8r+N3GuG5zrzxiC6w5ClwJMtXnap2t3cq/9V4nuKxCFIBjnT8dvoNMOOA3JZ0Cun+VaQrnocee9qyDl1AwkUkT01qSe6HovZUUE0vR1nVSrBFayx0TAK+fjPPfjcm0U68krM4N2puN7YFydgcTumSZL+/8Mr2P0zkB4Axc/BaA12dmmu0bW0IK4L7i6g648cmoNbM0/rHokfQINUnw5Gx77pS32udVGFCSfPcvILk9ePrXEqAofFV0AXGa9Bs1GmpRsNM0mTzmXHjdVr6MostJhvfUoR4pKKKQKVW5pXjvimE5/IdGQ6pCBjhQHyvOhOBpXJPwBHwvi6c97a0kYzM/ETeYUa4btNKdxVzEzKP9b+VxR04bgk46brx6SU= saverioproto@Saverios-MacBook-Pro.local"
    }
  }
}
