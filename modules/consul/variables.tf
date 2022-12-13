variable "network" {
    type = string
    description = "The name of the docker network on which to put the Consul nodes"
}

variable "host_user" {
    type = string
}        

variable "host_ssh_private_key" {
}

variable "host_ip_address" {
}
