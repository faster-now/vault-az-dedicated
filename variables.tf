variable "resource_group_location" {
  #default     = "eastus"
  default     = "uksouth"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "email" {
  default = "me@somewhere.com"
}

variable "tfe_organization" {
  type = string
}

variable "unique_dns_prefix" {
  type = string
}

# variable "AZ-SSH-PRIV" {
#   description = "azureuser ssh private key (generated by TF when the Azure VM is created)"
# }