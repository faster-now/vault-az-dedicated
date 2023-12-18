# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.hostname}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.hostname}-nic-config"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_address_id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = var.network_security_group_id
}