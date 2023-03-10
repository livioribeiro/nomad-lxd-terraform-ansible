resource "lxd_container" "vault_server" {
  depends_on = [module.packer]
  for_each   = local.vault_servers

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

resource "consul_acl_policy" "vault_server" {
  depends_on = [
    null_resource.provision_consul_server
  ]

  name  = "vault-server"
  rules = <<-EOT
    service "vault" {
      policy = "write"
    }
  EOT
}

resource "consul_acl_role" "vault_server" {
  name        = "vault-server"
  description = "Vault server role"

  policies = [
    "${consul_acl_policy.vault_server.id}"
  ]
}

resource "consul_acl_token" "vault_server" {
  description = "Vault server Consul acl token"
  roles       = [consul_acl_role.vault_server.name]
  local       = true
}

data "consul_acl_token_secret_id" "vault_server" {
  accessor_id = consul_acl_token.vault_server.id
}

resource "local_file" "vault_ansible_vars" {
  filename = "${path.module}/.tmp/ansible/ansible_vars.json"
  content = jsonencode({
    consul_token = data.consul_acl_token_secret_id.vault_server.secret_id
  })
}

resource "null_resource" "provision_vault_server" {
  depends_on = [
    lxd_container.vault_server,
    consul_acl_token_policy_attachment.annonymous_dns,
    local_file.vault_ansible_vars,
  ]

  provisioner "local-exec" {
    working_dir = "ansible"
    command = "ansible-playbook playbooks/vault-server/playbook.yaml -e @../${local_file.vault_ansible_vars.filename}"
  }
}
