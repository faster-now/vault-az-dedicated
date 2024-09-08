# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.hostname
  location                        = var.resource_group_location #as of 08/09/2024 b1s is no longer available via useast
  #location                        = "uksouth"
  resource_group_name             = var.resource_group_name
  network_interface_ids           = [azurerm_network_interface.nic.id]
  size                            = "Standard_B1s"
  #size                            = "Standard_B2pts_v2"
  computer_name                   = var.hostname
  admin_username                  = var.username
  disable_password_authentication = true
  availability_set_id             = var.availability_set_id

  os_disk {
    name                 = "${var.hostname}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.username
    public_key = var.public_key_openssh
  }

}