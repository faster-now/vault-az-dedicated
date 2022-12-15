resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  #zones               = ["1"]
  availability_zone   = "No-Zone"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  /* Considered this to enable Docker connection by TF but decided not to
    security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2375"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }*/
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
/*
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}*/

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "myVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_B1s"
  computer_name         = "myvm"
  admin_username        = "azureuser"
  disable_password_authentication = true

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  /*boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }*/
}

resource "null_resource" "bootstrap_ansible" {
  connection {
      type        = "ssh"
      user        = azurerm_linux_virtual_machine.my_terraform_vm.admin_username
      private_key = tls_private_key.example_ssh.private_key_pem #"${file("rajesh.pem")}"
      host        = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
    }

    provisioner "remote-exec" { #first try deleting private key incase it already exists to avoid scp permission denied error when trying to create it below
      inline = [
        "sudo rm -rf ~/az-ssh-priv.key | true" #try removing the file but dont give an error message and fail the plan if the file doesnt exist
      ]
    }

    provisioner "file" {
      content      = tls_private_key.example_ssh.private_key_pem
      destination = "~/az-ssh-priv.key"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -y python3-pip",
        "sudo pip3 install --upgrade pip",
        "pip3 install ansible",
        "pip3 install docker",
        "sudo gpasswd -a $USER docker",
        #"sudo newgrp docker",
        "sudo mkdir -p /tmp/ansible/",
        "sudo chmod 777 /tmp/ansible",
        "sudo mkdir -p /tmp/consul/",
        "sudo chmod 777 /tmp/consul",
        "sudo chmod 400 ~/az-ssh-priv.key"
        #"pip3 install ansible[azure]"
        /*"sudo amazon-linux-extras install ansible2 -y",
        "sudo yum install git -y",
        "git clone https://github.com/devops-school/ansible-hello-world-role /tmp/ans_ws",
        "ansible-playbook /tmp/ans_ws/site.yaml"*/
      ]
    }

    provisioner "file" {
      source      = "ansible/"
      destination = "/tmp/ansible"
    }

    provisioner "file" {
      source      = "consul/"
      destination = "/tmp/consul"
    }
/*
    provisioner "file" {
      source      = "ansible/hosts"
      destination = "/tmp/hosts"
    }

    provisioner "file" {
      source      = "ansible/ansible.cfg"
      destination = "/tmp/ansible.cfg"
    }

    provisioner "file" {
      source      = "ansible/bootstrap-docker.yml"
      destination = "/tmp/bootstrap-docker.yml"
    }*/

    provisioner "remote-exec" {
      inline = [
       # "sudo mkdir -p ~/consul-storage",
        
        "sudo mkdir -p /etc/ansible/",
        "sudo cp /tmp/ansible/hosts /etc/ansible/hosts",
        "sudo cp /tmp/ansible/ansible.cfg /etc/ansible/ansible.cfg",
        "sudo rm -rf /tmp/ansible",

        "sudo mkdir -p ~/consul",
        "sudo cp /tmp/consul/*.hcl ~/consul",
        "sudo rm /tmp/consul/*.hcl",

        "sudo mkdir -p ~/consul-build",
        "sudo cp -R /tmp/consul/* ~/consul-build",
        "sudo rm -rf /tmp/consul"
        ]
    }

    depends_on = [
      azurerm_linux_virtual_machine.my_terraform_vm
    ]
    triggers = {ip=azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address}
}

resource "null_resource" "bootstrap_docker" {
  connection {
      type        = "ssh"
      user        = azurerm_linux_virtual_machine.my_terraform_vm.admin_username
      private_key = tls_private_key.example_ssh.private_key_pem #"${file("me.pem")}"
      host        = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
    }
    provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -y ca-certificates",
        "sudo apt-get install -y curl",
        "sudo apt-get install -y gnupg",
        "sudo apt-get install -y lsb-release",
        "sudo mkdir -p /etc/apt/keyrings",
        "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg",
        "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
        "sudo apt-get update",
        "sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin"
        #"pip3 install ansible[azure]"
        /*"sudo amazon-linux-extras install ansible2 -y",
        "sudo yum install git -y",
        "git clone https://github.com/devops-school/ansible-hello-world-role /tmp/ans_ws",
        "ansible-playbook /tmp/ans_ws/site.yaml"*/
      ]
    }

    depends_on = [
      azurerm_linux_virtual_machine.my_terraform_vm,
      null_resource.bootstrap_ansible
    ]
    triggers = {ip=azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address}
}

/*resource "docker_network" "vault_network" {
  name = "vault_network"
}

module "provision_consul_container" {
  source                  = "./modules/consul"
  host_user               = azurerm_linux_virtual_machine.my_terraform_vm.admin_username
  host_ssh_private_key    = tls_private_key.example_ssh.private_key_pem
  host_ip_address         = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
  network                 = docker_network.vault_network.name


} */