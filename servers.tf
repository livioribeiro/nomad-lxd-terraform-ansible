resource "lxd_container" "dns_server" {
  for_each = local.dns_servers
  name     = each.key
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data" = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
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

resource "lxd_container" "consul_server" {
  for_each = local.consul_servers
  name     = each.key
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data" = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
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

resource "lxd_container" "vault_server" {
  for_each = local.vault_servers
  name     = each.key
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data" = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
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

resource "lxd_container" "nomad_server" {
  for_each = local.nomad_servers
  name     = each.key
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data"      = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
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

resource "lxd_container" "nomad_infra_client" {
  for_each = local.nomad_infra_clients
  name     = each.key
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data"      = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
      { address = each.value }
    )
    "limits.cpu"                = 1
    "limits.memory"             = "2GB"
    "security.nesting"          = true
    "security.privileged"       = true
    "raw.lxc" : <<-EOT
      lxc.apparmor.profile=unconfined
      lxc.cgroup.devices.allow=a
      lxc.cap.drop=
    EOT
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

resource "lxd_container" "nomad_apps_client" {
  for_each = local.nomad_apps_clients
  name     = each.key
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data"      = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
      { address = each.value }
    )
    "limits.cpu"                = 1
    "limits.memory"             = "2GB"
    "security.nesting"          = true
    "security.privileged"       = true
    "raw.lxc"                   = <<-EOT
      lxc.apparmor.profile=unconfined
      lxc.cgroup.devices.allow=a
      lxc.cap.drop=
    EOT
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

resource "lxd_container" "nfs_server" {
  name     = local.nfs_server.name
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data"      = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
      { address = local.nfs_server.host }
    )
    "security.privileged"       = true
    "raw.apparmor"              = "mount fstype=rpc_pipefs, mount fstype=nfsd,"
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

resource "lxd_container" "load_balancer" {
  name     = local.load_balancer.name
  image    = lxd_cached_image.ubuntu_base.fingerprint
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.user-data"      = local.cloud_init
    "cloud-init.network-config" = templatefile(
      "${path.module}/network-config.yaml",
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
