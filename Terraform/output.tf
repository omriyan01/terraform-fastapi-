output "vm_db_public_ip" {
  description = "Public IP address of the database virtual machine"
  value       = azurerm_public_ip.vm_db_public_ip.ip_address
}

output "vm_app_public_ip" {
  description = "Public IP address of the application virtual machine"
  value       = azurerm_public_ip.vm_app_public_ip.ip_address
}

output "vm_db_private_ip" {
  description = "Private IP address of the database virtual machine"
  value       = azurerm_network_interface.nic_omri_db.private_ip_address
}

output "vm_app_private_ip" {
  description = "Private IP address of the application virtual machine"
  value       = azurerm_network_interface.nic_omri_app.private_ip_address
}