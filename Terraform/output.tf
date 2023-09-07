output "app_vm_private_ip" {
  value = azurerm_network_interface.nic-omri-app.private_ip_address
}

output "db_vm_private_ip" {
  value = azurerm_network_interface.nic-omri-db.private_ip_address
}

output "app_vm_public_ip" {
  value = azurerm_public_ip.vm-web-public-ip.ip_address
}

output "db_vm_public_ip" {
  value = azurerm_public_ip.vm-db-public-ip.ip_address
}
