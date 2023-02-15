resource "lxd_container" "nomad_server" {
  depends_on = [module.packer]
  for_each = local.nomad_servers

  name     = each.key
  image    = "local:consul"
  profiles = [lxd_profile.nomad.name]

  config = {
    "user.access_interface" = "eth0"
    "cloud-init.network-config" = templatefile(
      "${path.module}/config/network-config.yaml",
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

# Consul ACL
resource "consul_acl_policy" "nomad_server" {
  depends_on = [null_resource.provision_consul_server]

  name  = "nomad-server"
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

    acl = "write"
  EOT
}

resource "consul_acl_role" "nomad_server" {
  name        = "nomad-server"
  description = "Nomad server role"

  policies = [
    "${consul_acl_policy.nomad_server.id}"
  ]
}

resource "consul_acl_token" "nomad_server" {
  description = "Nomad server Consul acl token"
  roles       = [consul_acl_role.nomad_server.name]
  local       = true
}

data "consul_acl_token_secret_id" "nomad_server" {
  accessor_id = consul_acl_token.nomad_server.id
}

# Vault token
data "local_file" "vault_nomad_token" {
  depends_on = [null_resource.vault_nomad_acl]

  filename = "vault/vault_nomad_token.txt"
}

resource "local_file" "nomad_ansible_vars" {
  filename = "${path.module}/.tmp/ansible/nomad_vars.json"
  content = jsonencode({
    consul_token = data.consul_acl_token_secret_id.nomad_server.secret_id
    vault_token  = data.local_file.vault_nomad_token.content
  })
}

resource "null_resource" "provision_nomad_server" {
  depends_on = [
    lxd_container.nomad_server,
    consul_acl_token_policy_attachment.annonymous_dns,
  ]

  provisioner "local-exec" {
    working_dir = "ansible"
    command     = "ansible-playbook playbooks/nomad-server/playbook.yaml -e @../${local_file.nomad_ansible_vars.filename}"
  }
}
