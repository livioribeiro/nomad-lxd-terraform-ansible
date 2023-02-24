resource "lxd_container" "load_balancer" {
  depends_on = [module.packer]

  name     = local.load_balancer.name
  image    = "local:base"
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.network-config" = templatefile(
      "${path.module}/cloud-init/network-config.yaml",
      { address = local.load_balancer.host }
    )
  }

  device {
    name = "map_port_80"
    type = "proxy"
    properties = {
      listen  = "tcp:0.0.0.0:80"
      connect = "tcp:127.0.0.1:80"
    }
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.cluster_ssh.private_key_pem
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = ["echo 1"]
  }
}

resource "null_resource" "provision_load_balancer" {
  depends_on = [
    lxd_container.load_balancer,
    null_resource.provision_consul_server,
  ]

  provisioner "local-exec" {
    working_dir = "ansible"
    command     = "ansible-playbook playbooks/load-balancer/playbook.yaml"
  }
}
