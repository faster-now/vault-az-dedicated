resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

#To allow to VMs to work behind basic LB they need to be in the same availability zone
resource "azurerm_availability_set" "vault" {
  name                = "vault-vms"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  platform_fault_domain_count = 2 #required after changing locaiton to uksouth on 08/09/2024 as default of 3 doesnt work in that location
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

# Create public IP for Vault server
resource "azurerm_public_ip" "vault_public_ip" {
  name                = "publicVaultIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  #zones               = ["1"]
  #availability_zone   = "No-Zone"
}

locals {
  my_local_ip = ["81.79.213.29/32"]
  tf_cloud_notification_ips = ["52.86.200.106/32","52.86.201.227/32","52.70.186.109/32","44.236.246.186/32","54.185.161.84/32","44.238.78.236/32"]
  allowed_ips = ["*"]
  #allowed_ips = setunion(local.my_local_ip, local.tf_cloud_notification_ips)
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

# Create (and display) an SSH key. In the current config this is used for all hosts
resource "tls_private_key" "ssh_allhosts" {
  algorithm = "RSA"
  rsa_bits  = 4096
}



#####Create Load Balancer###############################
resource "azurerm_lb" "vault_lb" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic" #Basic is the default but make it explicit so its obvious this is in the free tier

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pub_ip.id
  }
}

resource "azurerm_public_ip" "lb_pub_ip" {
  name                = "PublicIPForLB"
  domain_name_label   = var.unique_dns_prefix
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  #availability_zone   = "No-Zone"
}

resource "azurerm_lb_rule" "vault_lb_rule" {
  name                            = "VaultRule"
  loadbalancer_id                 = azurerm_lb.vault_lb.id
  protocol                        = "Tcp"
  frontend_port                   = 443
  backend_port                    = 8200
  frontend_ip_configuration_name  = "PublicIPAddress"
  #resource_group_name             = azurerm_resource_group.rg.name
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.vault_server_pool.id]
}

resource "azurerm_lb_backend_address_pool" "vault_server_pool" {
  loadbalancer_id = azurerm_lb.vault_lb.id
  name            = "vault-backend-pool"
}

locals {
  vault_hosts_public = ["vault-a"]
  #vault_hosts = ["vault-b","vault-c"]
  vault_hosts = ["vault-b"]
  #consul_hosts = ["consul-a", "consul-b", "consul-c", "consul-d", "consul-e"]
  consul_hosts = ["consul-a", "consul-b"]
}

# module "vault_hosts" {
#   for_each = toset(local.vault_hosts)
#   source = "./modules/cluster"
#   vault = true
#   hostname = each.value
#   public_key_openssh = tls_private_key.ssh_allhosts.public_key_openssh
#   network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
#   backend_address_pool_id = azurerm_lb_backend_address_pool.vault_server_pool.id
#   subnet_id = azurerm_subnet.my_terraform_subnet.id
#   resource_group_location = azurerm_resource_group.rg.location
#   resource_group_name  = azurerm_resource_group.rg.name
#   availability_set_id = azurerm_availability_set.vault.id
# }

# module "vault_hosts_public" {
#   for_each = toset(local.vault_hosts_public)
#   source = "./modules/cluster"
#   vault = true
#   hostname = each.value
#   public_key_openssh = tls_private_key.ssh_allhosts.public_key_openssh
#   network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
#   backend_address_pool_id = azurerm_lb_backend_address_pool.vault_server_pool.id
#   subnet_id = azurerm_subnet.my_terraform_subnet.id
#   resource_group_location = azurerm_resource_group.rg.location
#   resource_group_name  = azurerm_resource_group.rg.name
#   availability_set_id = azurerm_availability_set.vault.id
#   public_ip_address_id = azurerm_public_ip.vault_public_ip.id
#   ssh_priv_key = tls_private_key.ssh_allhosts.private_key_pem #Public host with Ansible needs private key for authenticating to other hosts
# }

# module "consul_hosts" {
#   for_each = toset(local.consul_hosts)
#   source = "./modules/cluster"
#   vault = false
#   hostname = each.value
#   public_key_openssh = tls_private_key.ssh_allhosts.public_key_openssh
#   network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
#   backend_address_pool_id = azurerm_lb_backend_address_pool.vault_server_pool.id
#   subnet_id = azurerm_subnet.my_terraform_subnet.id
#   resource_group_location = azurerm_resource_group.rg.location
#   resource_group_name  = azurerm_resource_group.rg.name
# }