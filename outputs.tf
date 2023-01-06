output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_public_ip_address" {
  value = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
}

output "lb_public_ip_address" {
  value = azurerm_public_ip.lb_pub_ip.ip_address
}

output "lb_domain_name" {
  value = azurerm_public_ip.lb_pub_ip.fqdn
}

output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}