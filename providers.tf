terraform {

backend "remote" {
    organization = "vault-c"

    workspaces {
      name = "vault-dev-az"
    }
  }
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~>4.0"
    }
   /* docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.23.1"
    } */
  }
}

provider "azurerm" {
  features {}
}

//provider "docker" {
 // host = "tcp://172.173.189.172:2375"
  #host     = "ssh://azureuser@172.173.189.172:22"
  #ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", "az-ssh-priv-key"]
//}

