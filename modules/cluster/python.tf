#Python is required on each host so that Ansible can interact it with it
resource "null_resource" "bootstrap_python" {
  connection {
      type        = "ssh"
      user        = azurerm_linux_virtual_machine.vm.admin_username
      private_key = var.ssh_priv_key #"${file("rajesh.pem")}"
      host        = azurerm_linux_virtual_machine.vm.public_ip_address
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -y python3-pip",
        "sudo pip3 install --upgrade pip",
      ]
    }
    triggers = {ip=azurerm_linux_virtual_machine.vm.private_ip_address}
}