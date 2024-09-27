# # Create Network Security Group and rule
# resource "azurerm_network_security_group" "my_terraform_nsg" {
#   name                = "myNetworkSecurityGroup"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   security_rule {
#     name                       = "SSH"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Vault"
#     priority                   = 1011
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "8200"
#     #source_address_prefixes      = local.allowed_ips
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Vault-b"
#     priority                   = 1031
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "8800"
#     #source_address_prefixes      = local.allowed_ips
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "VaultLB"
#     priority                   = 1021
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "443"
#     #source_address_prefixes    = local.allowed_ips
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   /**Temporary only for allowing generation of vault.smartec.cc certificate via certbot and LetsEncrypt*/
#   security_rule {
#     name                       = "Temp-Website"
#     priority                   = 1041
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     #source_address_prefixes      = local.allowed_ips
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

# }