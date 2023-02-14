resource "lxd_container" "nfs_server" {
  name     = local.nfs_server.name
  image    = module.packer.image_base
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.network-config" = templatefile(
      "${path.module}/config/network-config.yaml",
      { address = local.nfs_server.host }
    )
    "security.privileged" = true
    "raw.apparmor"        = "mount fstype=rpc_pipefs, mount fstype=nfsd,"
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

resource "null_resource" "provision_nfs_server" {
  depends_on = [
    lxd_container.nfs_server,
    null_resource.provision_dns_server,
  ]

  provisioner "local-exec" {
    working_dir = "ansible"
    command     = "ansible-playbook playbooks/nfs-server/playbook.yaml"
  }
}
