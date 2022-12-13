/*terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.23.1"
    }
  }
} */
/*

resource "docker_image" "consul" {
  name         = "consul:1.8.3"
  keep_locally = false
}

resource "docker_volume" "consul_config_volume" {
  name = "consul_config_volume"
}

resource "null_resource" "create_consul_config_file" {
  connection {
      type        = "ssh"
      user        = var.host_user
      private_key = var.host_ssh_private_key
      host        = var.host_ip_address
    }
    provisioner "file" {
          source      = "modules/consul/consul-generic.hcl"
          destination = docker_volume.consul_config_volume.name
    }
    
   # triggers = {ip=var.host_ip_address }
}

resource "docker_container" "consul-a" {
  image = docker_image.consul.latest
  name  = "consul-a"
  command = ["consul"]
  ports {
    internal = 7300
    external = 7300
  }
  ports {
    internal = 7301
    external = 7301
  }
  ports {
    internal = 7500
    external = 7500
  }

  volumes {
    container_path = "/consul/config"
    volume_name = docker_volume.consul_config_volume.name
  }
  networks_advanced {
    name = var.network
  }
  depends_on = [
      null_resource.create_consul_config_file]
}

*/