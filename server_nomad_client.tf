resource "lxd_container" "nomad_infra_client" {
  depends_on = [module.packer]
  for_each   = local.nomad_infra_clients

  name     = each.key
  image    = "local:nomad-client"
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.network-config" = templatefile(
      "${path.module}/cloud-init/network-config.yaml",
      { address = each.value }
    )
    "limits.cpu"          = 1
    "limits.memory"       = "2GB"
    "security.nesting"    = true
    "security.privileged" = true
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
  depends_on = [module.packer]
  for_each   = local.nomad_apps_clients

  name     = each.key
  image    = "local:nomad-client"
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.network-config" = templatefile(
      "${path.module}/cloud-init/network-config.yaml",
      { address = each.value }
    )
    "limits.cpu"          = 1
    "limits.memory"       = "2GB"
    "security.nesting"    = true
    "security.privileged" = true
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

resource "consul_acl_policy" "nomad_client" {
  depends_on = [
    null_resource.provision_consul_server
  ]

  name  = "nomad-client"
  rules = <<-EOT
    agent_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "write"
    }

    key_prefix "" {
      policy = "read"
    }
  EOT
}

resource "consul_acl_role" "nomad_client" {
  name        = "nomad-client"
  description = "Nomad client role"

  policies = [
    "${consul_acl_policy.nomad_client.id}"
  ]
}

resource "consul_acl_token" "nomad_client" {
  description = "Nomad client Consul acl token"
  roles       = [consul_acl_role.nomad_client.name]
  local       = true
}

data "consul_acl_token_secret_id" "nomad_client" {
  accessor_id = consul_acl_token.nomad_client.id
}

resource "local_file" "nomad_client_ansible_vars" {
  filename = "${path.module}/.tmp/ansible/nomad_client_vars.json"
  content = jsonencode({
    consul_token = data.consul_acl_token_secret_id.nomad_client.secret_id
  })
}

resource "null_resource" "provision_nomad_client" {
  depends_on = [
    lxd_container.nomad_infra_client,
    lxd_container.nomad_apps_client,
    null_resource.provision_nomad_server,
  ]

  provisioner "local-exec" {
    working_dir = "ansible"
    command     = "ansible-playbook playbooks/nomad-client/playbook.yaml -e @../${local_file.nomad_client_ansible_vars.filename}"
  }
}

# resource "null_resource" "provision_nomad_client_docker_registry" {
#   depends_on = [
#     module.nomad
#   ]

#   provisioner "local-exec" {
#     working_dir = "ansible"
#     command     = "ansible-playbook playbooks/nomad-client/configure-registry.yaml"
#   }
# }