resource "random_id" "consul_encrypt_key" {
  byte_length = 32
}

resource "local_file" "ansible_vars" {
  filename = "${path.module}/ansible/inventory/vars.json"
  content = jsonencode({
    all = {
      vars = {
        ubuntu_version          = var.ubuntu_version
        external_domain         = var.external_domain
        apps_subdomain          = var.apps_subdomain
        local_cluster_domain    = var.local_cluster_domain
        consul_management_token = local.consul_management_token
        consul_encrypt_key      = random_id.consul_encrypt_key.b64_std
        ca_cert                 = tls_self_signed_cert.nomad_cluster.cert_pem
        consul_certs = {
          cert        = tls_locally_signed_cert.consul.cert_pem
          private_key = tls_private_key.consul.private_key_pem
        }
        vault_certs = {
          cert        = tls_locally_signed_cert.vault.cert_pem
          private_key = tls_private_key.vault.private_key_pem
        }
        nomad_certs = {
          cert        = tls_locally_signed_cert.nomad.cert_pem
          private_key = tls_private_key.nomad.private_key_pem
        }
      }
    }
  })
}

resource "local_file" "ansible_hosts" {
  filename = "${path.module}/ansible/inventory/hosts"
  content  = <<EOT
[dns_servers]
%{for name, host in local.dns_servers~}
${name} ansible_host=${host}
%{endfor~}

[consul_servers]
%{for name, host in local.consul_servers~}
${name} ansible_host=${host}
%{endfor~}

[vault_servers]
%{for name, host in local.vault_servers~}
${name} ansible_host=${host}
%{endfor~}

[nomad_servers]
%{for name, host in local.nomad_servers~}
${name} ansible_host=${host}
%{endfor~}

[nomad_infra_clients]
%{for name, host in local.nomad_infra_clients~}
${name} ansible_host=${host}
%{endfor~}

[nomad_apps_clients]
%{for name, host in local.nomad_apps_clients~}
${name} ansible_host=${host}
%{endfor~}

[nomad_clients]
[nomad_clients:children]
nomad_infra_clients
nomad_apps_clients

[consul_clients]
[consul_clients:children]
vault_servers
nomad_servers
nomad_clients

[cluster]
${local.nfs_server.name} ansible_host=${local.nfs_server.host}
${local.load_balancer.name} ansible_host=${local.load_balancer.host}

[cluster:children]
dns_servers
consul_servers
vault_servers
nomad_servers
nomad_clients
  EOT
}