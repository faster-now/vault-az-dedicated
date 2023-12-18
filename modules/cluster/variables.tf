variable "vault_servers" {
    type = list
    default     = ["vault-a","vault-b","vault-c"]
    description = "Vault server names to create"
}

variable "consul_servers" {
    type = list
    default     = ["consul-a","consul-b","consul-c","consul-d","consul-e"]
    description = "Consul server names to create"
}

variable "vault" {
    type = bool
    default = false
    description = "Whether the vm is a Vault server (so should be included in load balancing)"
}

variable "hostname" {
    description = "The hostname of the VM"
}

variable "username" {
    type = string
    default = "azureuser"
    description = "The username of the admin account. Note the ansible.cfg file also refers to this"
}

variable "public_key_openssh" {
    type = string
    description = "The public key part of the SSH key to install onto the host"
}

#variable "network_interface_id" {
#    type = String
#    description = "The ID of the network interface"
#}

variable "network_security_group_id" {
    type = string
    description = "The ID of the network security group"
}

variable "backend_address_pool_id" {
    type = string
    description = "The ID of the load balancer backend server pool"
}

variable "subnet_id" {
    type = string
    description = "The ID of the network subnet this VM will reside in"
}

variable "resource_group_location" {
    type = string
    description = "The location of the resource group"
}

variable "resource_group_name" {
    type = string
    description = "The name of the resource group"
}

variable "availability_set_id" {
    type = string
    default = null
    description = "The id of the availability zone to place the VM"
}

variable "public_ip_address_id" {
    type = string
    default = null
    description = "The ID of the public IP address of the VM"
}

variable "ssh_priv_key" {
    type = string
    default = null
    description = "The PEM of the private key. Written to host for use by Ansible"
}


