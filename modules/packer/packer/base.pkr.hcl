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

  provisioner "file" {
    destination = "/etc/dnsmasq.conf"
    content = <<-EOT
      port=53
      listen-address=127.0.0.1
      no-dhcp-interface=lo
      bind-interfaces
      no-resolv

      server=9.9.9.9
      server=149.112.112.112
    EOT
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]

    inline = [
      "echo '${var.ssh_key}' > /home/ubuntu/.ssh/authorized_keys",
      "apt-get update",
      "apt-get install -y openssh-server",
      "apt-get install -o 'DPkg::Options::=--force-confdef' -y dnsmasq",

      "systemctl stop systemd-resolved",
      "systemctl disable systemd-resolved",
    ]
  }

  provisioner "file" {
    destination = "/etc/resolv.conf"
    content = <<-EOT
      127.0.0.1
      options edns0 trust-ad
    EOT
  }
}
