#configuring a rg
resource "azurerm_resource_group" "rg_omri_terraform" {
  name     = var.resource_group_name
  location = var.location
}

# configuring a vnet
resource "azurerm_virtual_network" "vnet_omri_dev_westeu" {
  name                = "vnet-omri-dev-westeu"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  location            = azurerm_resource_group.rg_omri_terraform.location
  address_space       = ["10.0.0.0/16", "10.2.0.0/16"]
}

#configuring 2 subnets
resource "azurerm_subnet" "app_subnet" {
  name                 = "snet-omri-app"
  resource_group_name  = azurerm_resource_group.rg_omri_terraform.name
  virtual_network_name = azurerm_virtual_network.vnet_omri_dev_westeu.name
  address_prefixes     = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-db-westeu"
  resource_group_name  = azurerm_resource_group.rg_omri_terraform.name
  virtual_network_name = azurerm_virtual_network.vnet_omri_dev_westeu.name
  address_prefixes     = ["10.2.0.0/16"]
}

#configuring a web nsg
resource "azurerm_network_security_group" "nsg-app" {
  location            = azurerm_resource_group.rg_omri_terraform.location
  name                = "nsg-terraform-prod-app"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  security_rule {
    name                       = "opentowebonport80,8080,5000"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = ["80","8080","5000"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allowsshtoprivateip"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#configuring a db nsg
resource "azurerm_network_security_group" "nsg-omri-db" {
  location            = azurerm_resource_group.rg_omri_terraform.location
  name                = "nsg-omri-db"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  security_rule {
    name                       = "port5432opentowebsnet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = 5432
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allowsshtoprivateip"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#connecting the app sub net to web-omri-nsg
resource "azurerm_subnet_network_security_group_association" "nsg-app-con" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-omri-db.id
}

#connecting db sub net to db-omri-nsg
resource "azurerm_subnet_network_security_group_association" "nsg-db-con" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-omri-db.id
}

#creating public ip for web-vm
resource "azurerm_public_ip" "vm-web-public-ip" {
  name                = "vm-app-public-ip"
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg_omri_terraform.location
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  sku = "Basic"
}

#creating public ip for db-vm
resource "azurerm_public_ip" "vm-db-public-ip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg_omri_terraform.location
  name                = "vm-db-public-ip"
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name
  sku = "Basic"
}

#configuring network interface for app-vm
resource "azurerm_network_interface" "nic-omri-app" {
  name                = "nic-omri-app"
  location            = azurerm_resource_group.rg_omri_terraform.location
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     =  azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm-web-public-ip.id
  }
}

#configuring network interface for db-vm
resource "azurerm_network_interface" "nic-omri-db" {
  name                = "nic-omri-db"
  location            = azurerm_resource_group.rg_omri_terraform.location
  resource_group_name = azurerm_resource_group.rg_omri_terraform.name



  ip_configuration {
    name                          = "internal"
    subnet_id                     =  azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address   = "10.2.0.4"
    public_ip_address_id = azurerm_public_ip.vm-db-public-ip.id
    primary              = true
  }
}

# #configure ssh key
# resource "tls_private_key" "vm_ssh" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }

# resource "local_file" "ssh_pem" {
#   filename = "${path.module}\\web_db_key.pem"
#   content = tls_private_key.vm_ssh.private_key_pem
# }

#create vm for app
resource "azurerm_linux_virtual_machine" "vm-omri-app" {
  name                            = "vm-omri-app"
  resource_group_name             = azurerm_resource_group.rg_omri_terraform.name
  location                        = azurerm_resource_group.rg_omri_terraform.location
  size                            = "Standard_B1ls"
  admin_username                  = var.vm_user
  admin_password                  = var.vm_password
  disable_password_authentication = false
  network_interface_ids           = [
    azurerm_network_interface.nic-omri-app.id,
  ]
  # admin_ssh_key {
  #   public_key = tls_private_key.vm_ssh.public_key_openssh
  #   username   = var.admin_user
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-minimal-jammy"
    sku       = "minimal-22_04-lts-gen2"
    version   = "latest"
  }
  depends_on = [
    azurerm_linux_virtual_machine.vm-db
  ]
}

#creating vm for db
resource "azurerm_linux_virtual_machine" "vm-omri-db" {
  name                            = "vm-omri-db"
  resource_group_name             = azurerm_resource_group.rg_omri_terraform.name
  location                        = azurerm_resource_group.rg_omri_terraform.location
  size                            = "Standard_B1ls"
  admin_username                  = var.vm_username
  admin_password                  = var.vm_password
  disable_password_authentication = false
  network_interface_ids           = [
    azurerm_network_interface.nic-omri-db.id,
  ]
  # admin_ssh_key {
  #   public_key = tls_private_key.vm_ssh.public_key_openssh
  #   username   = var.admin_user
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-minimal-jammy"
    sku       = "minimal-22_04-lts-gen2"
    version   = "latest"
  }
}


#create app vm managed disk
resource "azurerm_managed_disk" "app-omri-disk" {
  name                 = "${azurerm_linux_virtual_machine.vm-omri-app.name}-disk1"
  location             = azurerm_resource_group.rg_omri_terraform.location
  resource_group_name  = azurerm_resource_group.rg_omri_terraform.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}
#attach web disk to app vm
resource "azurerm_virtual_machine_data_disk_attachment" "app_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.app-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-omri-app.id
  lun                = "10"
  caching            = "ReadWrite"
}
#web provision to mount disk
# resource "null_resource" "web_vm_null" {
#   connection {
#     type = "ssh"
#     user = var.admin_user
#     private_key = tls_private_key.vm_ssh.private_key_pem
#     host = azurerm_linux_virtual_machine.vm-web.public_ip_address
#   }
#   provisioner "remote-exec" {
#     inline=[
#       "sudo mkfs -t ext4 /dev/sdc",
#       "sudo mkdir /data1",
#       "sudo mount /dev/sdc /data1"
#     ]
#   }
#   depends_on = [
#     azurerm_virtual_machine_data_disk_attachment.web_disk_attach
#   ]
#   triggers = {
#     always_run = timestamp()
#   }
# }

#create db vm managed disk
resource "azurerm_managed_disk" "db-omri-disk" {
  name                 = "${azurerm_linux_virtual_machine.vm-omri-db.name}-disk1"
  location             = azurerm_resource_group.rg_omri_terraform.location
  resource_group_name  = azurerm_resource_group.rg_omri_terraform.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}
#attach db disk to web vm
resource "azurerm_virtual_machine_data_disk_attachment" "db_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.db-disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-omri-db.id
  lun                = "10"
  caching            = "ReadWrite"
}
# #db provision to mount disk
# resource "null_resource" "db_vm_null" {
#   connection {
#     type = "ssh"
#     user = var.admin_user
#     private_key = tls_private_key.vm_ssh.private_key_pem
#     host = azurerm_linux_virtual_machine.vm-db.public_ip_address
#   }
#   provisioner "remote-exec" {
#     inline= [
#       "sudo mkfs -t ext4 /dev/sdc",
#       "sudo mkdir /data1",
#       "sudo mount /dev/sdc /data1"
#       ]
#   }
#   depends_on = [
#     azurerm_virtual_machine_data_disk_attachment.db_disk_attach
#   ]
#   triggers = {
#     always_run = timestamp()
#   }
# }


#creating db extension
resource "azurerm_virtual_machine_extension" "vm-db-extension" {
  name                 = "vm-db-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm-omri-db.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
{
  "commandToExecute": "sudo apt-get update && sudo apt install git -y && git clone ${var.git_repo} && sudo bash ${var.extension_git_path}/database_script.sh "
}
SETTINGS

  depends_on = [
  azurerm_linux_virtual_machine.vm-omri-db
  ]
}

#creating web extension
resource "azurerm_virtual_machine_extension" "vm-app-extension" {
  name                 = "vm-app-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm-omri-app.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
{
  "commandToExecute": "sudo apt-get update && sudo apt install git -y && git clone ${var.git_repo} && sudo bash ${var.extension_git_path}/app_script.sh '"
}
SETTINGS

  depends_on = [
  azurerm_linux_virtual_machine.vm-omri-db,
    azurerm_virtual_machine_extension.vm-db-extension,
    azurerm_linux_virtual_machine.vm-omri-app
  ]
}
