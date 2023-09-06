# Define the Azure Resource Group
provider "azurerm" {
  features {}
}

# data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg_omri_terraform" {
  name     = "rg_omri_terraform"
  location = var.location
}

# Create Network Security Groups
resource "azurerm_network_security_group" "nsg_omri_db" {
  name                = "nsg-omri-db"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
}

resource "azurerm_network_security_group" "nsg_omri_web" {
  name                = "nsg-omri-web"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
}

# Create Network Security Group Rules
resource "azurerm_network_security_rule" "db_allow_custom_5432_inbound" {
  name                        = "AllowCidrBlockCustom5432Inbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg_omri_db.name
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
}

# Create nsg_omri_db rule
resource "azurerm_network_security_rule" "db_allow_my_ip_22_inbound" {
  name                        = "AllowMyIpAddressCustom22Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg_omri_db.name
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
}

# Create nsg_omri_web rule
resource "azurerm_network_security_rule" "web_allow_custom_web" {
  name                        = "AllowAnyCustomWeb"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_ranges      = ["80", "8080", "5000"]
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg_omri_web.name
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
}

# Create nsg_omri_web rule
resource "azurerm_network_security_rule" "web_allow_my_ip_ssh_inbound" {
  name                        = "AllowMyIpAddressSSHInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg_omri_web.name
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet_omri_dev_westeu" {
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  name                = "vnet-omri-dev-westeu"
  location            = var.location
  address_space       = ["10.0.0.0/16", "10.2.0.0/16"]
}

# Create Subnets
resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-omri-db"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  virtual_network_name = azurerm_virtual_network.vnet_omri_dev_westeu.name
  address_prefixes       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "snet-omri-web"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  virtual_network_name = azurerm_virtual_network.vnet_omri_dev_westeu.name
  address_prefixes       = ["10.0.0.0/16"]
}


# Create virtual machine db 
resource "azurerm_linux_virtual_machine" "vm_omri_db" {
  name                = "vm-omri-db"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = var.vm_username
  admin_password      = var.vm_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic_omri_db.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  # depends_on = [ azurerm_key_vault_secret.vm_pass ]
}
# Create virtual machine app 
resource "azurerm_linux_virtual_machine" "vm_omri_app" {
  name                = "vm-omri-app"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = var.vm_username
  admin_password      = var.vm_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic_omri_app.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  # depends_on = [ azurerm_key_vault_secret.vm_pass ]
}
# create netwotk interface
resource "azurerm_network_interface" "nic_omri_db" {
  name                = "nic-omri-db"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name

  ip_configuration {
    name                          = "ipconfig-omri-db"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm_db_public_ip.id
  }
}

resource "azurerm_network_interface" "nic_omri_app" {
  name                = "nic-omri-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name

  ip_configuration {
    name                          = "ipconfig-omri-app"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
     public_ip_address_id = azurerm_public_ip.vm_app_public_ip.id
  }
}
# Create Managed Disks for VMs
resource "azurerm_managed_disk" "disk_omri_db" {
  name                 = "disk-omri-db"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg_omri_terraform.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb_db
}


resource "azurerm_managed_disk" "disk_omri_app" {
  name                 = "disk-omri-app"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg_omri_terraform.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb_app
}
resource "azurerm_virtual_machine_data_disk_attachment" "disk_mount_vm_db" {
  managed_disk_id    = azurerm_managed_disk.disk_omri_db.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm_omri_db.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_mount_vm_app" {
  managed_disk_id    = azurerm_managed_disk.disk_omri_app.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm_omri_app.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_public_ip" "vm_db_public_ip" {
  name                = "vm-db-public-ip"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  location            = azurerm_resource_group.rg_omri_terraform.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
resource "azurerm_public_ip" "vm_app_public_ip" {
  name                = "vm-app-public-ip"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  location            = azurerm_resource_group.rg_omri_terraform.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
resource "azurerm_virtual_machine_extension" "vm_db_extansion" {
  name = "vm-db-extansion"
  virtual_machine_id = azurerm_linux_virtual_machine.vm_omri_db.id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"


settings = <<SETTINGS
{
   "script": "${base64encode(file("${path.module}//script.sh"))}"
}
SETTINGS

  depends_on = [
  azurerm_linux_virtual_machine.vm_omri_db
  ]
}
resource "azurerm_virtual_machine_extension" "vm_app_extansion" {
  name = "vm-app-extansion"
  virtual_machine_id = azurerm_linux_virtual_machine.vm_omri_app.id
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"


settings = <<SETTINGS
{
   "script": "${base64encode(file("${path.module}//app_script.sh"))}"
}
SETTINGS

  depends_on = [
  azurerm_linux_virtual_machine.vm_omri_app
  ]
}
