terraform {

backend "remote" {
    organization = "vault-c"

    workspaces {
      name = "vault-az-dedicated"
    }
  }
  #required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.85"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~>4.0"
    }
    # tfe = {
    #   version = "~> 0.40.0"
    # }
   /* docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.23.1"
    } */
  }
}

provider "azurerm" {
  features {}
}

# provider "tfe" {
#   #hostname = var.hostname
#   #token    = var.token
# }

//provider "docker" {
 // host = "tcp://172.173.189.172:2375"
  #host     = "ssh://azureuser@172.173.189.172:22"
  #ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", "az-ssh-priv-key"]
//}

