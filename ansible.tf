resource "random_id" "consul_encrypt_key" {
  byte_length = 32
}

resource "random_id" "nomad_encrypt_key" {
  byte_length = 32
}

resource "local_file" "ansible_vars" {
  filename = "${path.module}/.tmp/ansible/inventory/vars.json"
  content = jsonencode({
    all = {
      vars = {
        root_tmp_dir            = "${abspath(path.module)}/.tmp"
        ubuntu_version          = var.ubuntu_version
        external_domain         = var.external_domain
        apps_subdomain          = var.apps_subdomain
        ca_cert                 = tls_self_signed_cert.nomad_cluster.cert_pem
        consul_management_token = local.consul_management_token
        consul_encrypt_key      = random_id.consul_encrypt_key.b64_std
        nomad_encrypt_key       = random_id.nomad_encrypt_key.b64_std

        consul_server_certs = {
          cert        = tls_locally_signed_cert.consul.cert_pem
          private_key = tls_private_key.consul.private_key_pem
        }

        consul_client_certs = {
          cert        = tls_locally_signed_cert.consul_client.cert_pem
          private_key = tls_private_key.consul_client.private_key_pem
        }

        vault_certs = {
          cert        = tls_locally_signed_cert.vault.cert_pem
          private_key = tls_private_key.vault.private_key_pem
        }

        nomad_server_certs = {
          cert        = tls_locally_signed_cert.nomad_server.cert_pem
          private_key = tls_private_key.nomad_server.private_key_pem
        }

        nomad_client_certs = {
          cert        = tls_locally_signed_cert.nomad_client.cert_pem
          private_key = tls_private_key.nomad_client.private_key_pem
        }
      }
    }
  })
}

resource "local_file" "ansible_hosts" {
  filename = "${path.module}/.tmp/ansible/inventory/hosts"
  content = <<EOT
[consul_servers]
%{for server in lxd_container.consul_server~}
${server.name} ansible_host=${server.ipv4_address}
%{endfor~}

[vault_servers]
%{for server in lxd_container.vault_server~}
${server.name} ansible_host=${server.ipv4_address}
%{endfor~}

[nomad_servers]
%{for server in lxd_container.nomad_server~}
${server.name} ansible_host=${server.ipv4_address}
%{endfor~}

[nomad_infra_clients]
%{for server in lxd_container.nomad_infra_client~}
${server.name} ansible_host=${server.ipv4_address}
%{endfor~}

[nomad_apps_clients]
%{for server in lxd_container.nomad_apps_client~}
${server.name} ansible_host=${server.ipv4_address}
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
${lxd_container.load_balancer.name} ansible_host=${lxd_container.load_balancer.ipv4_address}
${lxd_container.nfs_server.name} ansible_host=${lxd_container.nfs_server.ipv4_address}

[cluster:children]
consul_servers
vault_servers
nomad_servers
nomad_clients
  EOT
}