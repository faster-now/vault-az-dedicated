output "username" {
  value = azurerm_linux_virtual_machine.vm.admin_username
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}