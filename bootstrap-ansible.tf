# #The hostnames and IP addresses provisioned need inserted into an ansible inventory file and uploaded to the ansible host/master.
# #Also ansible needs installed along with required config, SSH priv key for connecting to hosts and build pack files for configuring the hosts
# resource "null_resource" "bootstrap_ansible" {
#     connection {
#         type        = "ssh"
#         user        = values(module.vault_hosts_public)[0].username #should only be one public host
#         private_key = tls_private_key.ssh_allhosts.private_key_pem
#         host        = values(module.vault_hosts_public)[0].public_ip_address
#     }

#     provisioner "remote-exec" { #first try deleting private key incase it already exists to avoid scp permission denied error when trying to create it below
#         inline = [
#             "sudo rm -rf ~/az-ssh-priv.key | true" #try removing the file but dont give an error message and fail the plan if the file doesnt exist
#         ]
#     }

#     provisioner "file" {
#         content      = tls_private_key.ssh_allhosts.private_key_openssh
#         destination = "az-ssh-priv.key"
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "sudo apt-get update",
#             "sudo apt-get install -y python3-pip",
#             "pipx install ansible-core",
#             "pipx ensurepath",
        
#             "sudo mkdir -p /tmp/build/",
#             "sudo chmod 777 /tmp/build",

#             "sudo chmod 400 ~/az-ssh-priv.key"
#             #"pip3 install ansible[azure]"
#             /*"sudo amazon-linux-extras install ansible2 -y",
#             "sudo yum install git -y",
#             "git clone https://github.com/devops-school/ansible-hello-world-role /tmp/ans_ws",
#             "ansible-playbook /tmp/ans_ws/site.yaml"*/
#         ]
#     }

#     #After build directory created on the host above, now upload the contents of the local build folder
#     provisioner "file" {
#       source      = "build/"
#       destination = "/tmp/build"
#     }

#     provisioner "file" {
#       content      = templatefile("${path.module}/inventory.tftpl", { consul_hosts = local.consul_hosts, 
#                                                                       vault_hosts = concat(local.vault_hosts, local.vault_hosts_public), 
#                                                                       ansible_hosts = local.vault_hosts_public
#                                                                       username = values(module.vault_hosts_public)[0].username})
#       destination = "/tmp/build/hosts"
#     }

#     provisioner "remote-exec" {
#       inline = [
#        # "sudo mkdir -p ~/consul-storage",
#         #files necessary for ansible to function
#         "sudo mkdir -p /etc/ansible/",
#         "sudo cp /tmp/build/hosts /etc/ansible/hosts",
#         "sudo cp /tmp/build/ansible/ansible.cfg /etc/ansible/ansible.cfg",
#         "sudo cp /tmp/build/ansible/config ~/.ssh/config",
#         "sudo cp /tmp/build/ansible/download-build-pack.yml ~/download-build-pack.yml",
#         "sudo rm -rf /tmp/build/",
#         ]
#     }

#     provisioner "remote-exec" {
#       inline = [
#        # "sudo mkdir -p ~/consul-storage",
#         #files necessary for ansible to function
#         "sudo mkdir -p ~/ansible/",
#         "sudo chown ${values(module.vault_hosts_public)[0].username}:${values(module.vault_hosts_public)[0].username} ~/ansible",
#         "/home/${values(module.vault_hosts_public)[0].username}/.local/bin/ansible-playbook ~/download-build-pack.yml",
#         "cd ~/ansible",
#         "/home/${values(module.vault_hosts_public)[0].username}/.local/bin/ansible-playbook ~/ansible/build-all.yml",
#         #"ansible-playbook -i inventory build-all.yml" #TODO commented kicking off the build until check infra layer is ok first
#         ]
#     }

#   #triggers = {ip=values(module.vault_hosts_public)[0].public_ip_address}
#   triggers = {username=values(module.vault_hosts_public)[0].username}
# }