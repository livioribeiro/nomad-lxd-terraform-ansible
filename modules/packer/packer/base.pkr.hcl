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

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]

    inline = [
      "apt-get update",
      "apt-get install -y openssh-server",
      "echo '${var.ssh_key}' > /home/ubuntu/.ssh/authorized_keys",
    ]
  }
}
