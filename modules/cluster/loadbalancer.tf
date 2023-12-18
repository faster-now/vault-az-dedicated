############################################################ Load Balancer related #########################################################
#Associate the IP of the VM server with the load balancers backend address pool (only Vault servers as Consul is not load balanced)
resource "azurerm_network_interface_backend_address_pool_association" "vault_pool_assoc" {
    count = var.vault ? 1 : 0
    network_interface_id    = azurerm_network_interface.nic.id
    ip_configuration_name   = azurerm_network_interface.nic.ip_configuration.0.name
    backend_address_pool_id = var.backend_address_pool_id
}
