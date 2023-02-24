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

variable "ssh_key" {
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

source "lxd" "base" {
  image = var.image_source
  container_name = "packer-base"
  output_image = "base"
  publish_properties = {
    description = "Base image for Nomad cluster"
  }
}

build {
  name = "base"
  sources = ["source.lxd.base"]

  provisioner "file" {
    destination = "/etc/apt/sources.list.d/hashicorp.list"
    content     = "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${var.ubuntu_version} main"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]

    inline = [
      "mkdir -p /home/ubuntu/.ssh",
      "echo '${var.ssh_key}' > /home/ubuntu/.ssh/authorized_keys",
      "echo '${local.hashicorp_gpg}' | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "apt-get update",
      "apt-get install -y openssh-server consul",
    ]
  }
}
