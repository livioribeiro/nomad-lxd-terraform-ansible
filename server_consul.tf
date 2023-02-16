locals {
  consul_management_token = uuidv5("dns", "management.consul.cluster.local")
}

resource "local_file" "consul_management_token" {
  filename = "${path.module}/.tmp/root_token_consul.txt"
  content  = local.consul_management_token
}

resource "lxd_container" "consul_server" {
  depends_on = [module.packer]
  for_each   = local.consul_servers

  name     = each.key
  image    = "local:consul"
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

resource "null_resource" "provision_consul_server" {
  depends_on = [
    lxd_container.consul_server,
    null_resource.provision_dns_server,
  ]

  provisioner "local-exec" {
    working_dir = "ansible"
    command     = "ansible-playbook playbooks/consul-server/playbook.yaml"
  }
}

resource "consul_acl_policy" "annonymous_dns" {
  depends_on = [null_resource.provision_consul_server]

  name  = "annonymous-dns"
  rules = <<-EOT
    # allow access to metrics
    agent_prefix "consul-server" {
      policy = "read"
    }

    # allow dns queries
    node_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "read"
    }
  EOT
}

# https://dickingwithdocker.com/2021/09/allowing-dns-lookups-with-hashicorp-consul-acls-enabled/
resource "consul_acl_token_policy_attachment" "annonymous_dns" {
  # annonymous token
  token_id = "00000000-0000-0000-0000-000000000002"
  policy   = consul_acl_policy.annonymous_dns.name
}
