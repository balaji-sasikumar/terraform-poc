terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
resource "azurerm_resource_group" "vmss" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags

}

resource "azurerm_virtual_network" "vmss" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name
  tags                = var.tags
}
resource "azurerm_network_security_group" "vmss" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name

  security_rule {
    name                       = "SSH"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 302
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 303
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags

}
resource "azurerm_subnet" "vmss" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.vmss.name
  virtual_network_name = azurerm_virtual_network.vmss.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "vmss" {
  subnet_id                 = azurerm_subnet.vmss.id
  network_security_group_id = azurerm_network_security_group.vmss.id
}


resource "azurerm_public_ip" "vmss" {
  name                = "${var.vm_name}-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name
  allocation_method   = "Static"
  tags                = var.tags
}
resource "azurerm_network_interface" "vmss" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = azurerm_subnet.vmss.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmss.id
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "vmss" {
  network_interface_id      = azurerm_network_interface.vmss.id
  network_security_group_id = azurerm_network_security_group.vmss.id
}

resource "azurerm_windows_virtual_machine" "vmss" {
  name                  = var.vm_name
  resource_group_name   = azurerm_resource_group.vmss.name
  location              = var.location
  size                  = var.vm_sku
  admin_username        = var.admin_user
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vmss.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }
  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "${var.vm_name}-custom-script"
  virtual_machine_id   = azurerm_windows_virtual_machine.vmss.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
  "commandToExecute": "powershell -command Invoke-WebRequest -Uri '${var.blob_url_to_install}' -OutFile 'C:\\install.exe'"
  }
  SETTINGS

  tags       = var.tags
  depends_on = [azurerm_windows_virtual_machine.vmss]
}

