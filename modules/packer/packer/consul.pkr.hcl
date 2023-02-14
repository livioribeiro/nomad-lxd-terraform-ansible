packer {
  required_plugins {
    lxd = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/lxd"
    }
  }
}

variable "image_source" {
  type = string
}

variable "ubuntu_version" {
  type    = string
  default = "jammy"
}

data "http" "hashicorp_gpg" {
  url = "https://apt.releases.hashicorp.com/gpg"
}

locals {
  hashicorp_gpg = data.http.hashicorp_gpg.body
}

source "lxd" "consul" {
  image          = var.image_source
  container_name = "packer-consul"
  output_image   = "consul"
  publish_properties = {
    description = "Consul base image for Nomad cluster"
  }
}

build {
  name = "consul"
  sources = ["source.lxd.consul"]

  provisioner "file" {
    destination = "/etc/apt/sources.list.d/hashicorp.list"
    content     = "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${var.ubuntu_version} main"
  }

  provisioner "file" {
    destination = "/etc/dnsmasq.conf"
    content = <<-EOT
      port=53
      listen-address=127.0.0.1
      no-dhcp-interface=lo
      bind-interfaces
      no-resolv

      server=1.1.1.1
      server=1.0.0.1
    EOT
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]

    inline = [
      "echo '${local.hashicorp_gpg}' | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg",
      "apt-get update",
      "apt-get install -o 'DPkg::Options::=--force-confdef' -y consul dnsmasq",
    ]
  }
}
