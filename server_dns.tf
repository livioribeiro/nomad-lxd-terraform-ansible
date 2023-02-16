resource "lxd_container" "dns_server" {
  depends_on = [module.packer]
  for_each   = local.dns_servers

  name     = each.key
  image    = "local:base"
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.network-config" = templatefile(
      "${path.module}/cloud-init/network-config.yaml",
      { address = each.value }
    )
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

resource "null_resource" "provision_dns_server" {
  depends_on = [lxd_container.dns_server]

  provisioner "local-exec" {
    working_dir = "ansible"
    command     = "ansible-playbook playbooks/dns-server/playbook.yaml"
  }
}
