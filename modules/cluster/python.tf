#Python is required on each host so that Ansible can interact it with it
# resource "null_resource" "bootstrap_python" {
#   connection {
#       type        = "ssh"
#       user        = azurerm_linux_virtual_machine.vm.admin_username
#       private_key = var.ssh_priv_key #"${file("rajesh.pem")}"
#       host        = azurerm_linux_virtual_machine.vm.private_ip_address 
#     }

#     provisioner "remote-exec" {
#       inline = [
#         "sudo apt-get update",
#         "sudo apt-get install -y python3-pip",
#         "sudo pip3 install --upgrade pip",
#       ]
#     }
#     triggers = {ip=azurerm_linux_virtual_machine.vm.private_ip_address}
# }


resource "azurerm_virtual_machine_extension" "bootstrap_python" {
  name                 = var.hostname
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "script": "${base64encode(templatefile("install-python.sh",{}))}"
 }
SETTINGS
#"commandToExecute": "hostname && uptime"
}