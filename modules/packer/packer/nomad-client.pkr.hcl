packer {
  required_plugins {
    lxd = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/lxd"
    }
  }
}

variable "cni_plugins_version" {
  type    = string
  default = "1.2.0"
}

variable "ubuntu_version" {
  type    = string
  default = "jammy"
}

data "http" "docker_gpg" {
  url = "https://download.docker.com/linux/ubuntu/gpg"
}

data "http" "envoy_gpg" {
  url = "https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key"
}

locals {
  docker_gpg      = data.http.docker_gpg.body
  envoy_gpg       = data.http.envoy_gpg.body
  cni_plugins_url = "https://github.com/containernetworking/plugins/releases/download/v${var.cni_plugins_version}/cni-plugins-linux-amd64-v${ var.cni_plugins_version }.tgz"
}

source "lxd" "nomad_client" {
  image           = "local:base"
  container_name  = "packer-nomad-client"
  output_image    = "nomad-client"
  publish_properties = {
    description = "Nomad client image for Nomad cluster"
  }
}

build {
  name = "nomad_client"
  sources = ["source.lxd.nomad_client"]

  provisioner "file" {
    destination = "/etc/apt/sources.list.d/docker.list"
    content     = "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${var.ubuntu_version} stable"
  }

  provisioner "file" {
    destination = "/etc/apt/sources.list.d/getenvoy.list"
    content     = "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu ${var.ubuntu_version} main"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]

    inline = [
      "echo '${local.docker_gpg}' | gpg --dearmor -o /usr/share/keyrings/docker.gpg",
      "echo '${local.envoy_gpg}' | gpg --dearmor -o /usr/share/keyrings/getenvoy.gpg",
      "apt-get update",
      // "apt-get install -y nomad docker-ce docker-ce-cli containerd.io getenvoy-envoy nfs-common",
      "apt-get install -y nomad docker.io getenvoy-envoy nfs-common",
      "mkdir -p /opt/cni/bin",
      "wget -O /tmp/cni-plugins.tgz ${local.cni_plugins_url}",
      "tar -vxf /tmp/cni-plugins.tgz -C /opt/cni/bin",
      "rm /tmp/cni-plugins.tgz",
      "usermod -aG docker nomad",
    ]
  }
}
