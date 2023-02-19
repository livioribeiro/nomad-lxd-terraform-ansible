# CA
resource "tls_private_key" "nomad_cluster" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "nomad_cluster" {
  private_key_pem = tls_private_key.nomad_cluster.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 87600
  early_renewal_hours   = 720
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

resource "local_file" "cluster_ca_cert" {
  filename = "${path.module}/.tmp/certs/ca.pem"
  content  = tls_self_signed_cert.nomad_cluster.cert_pem
}

# Consul
resource "tls_private_key" "consul" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "consul" {
  private_key_pem = tls_private_key.consul.private_key_pem
  dns_names       = concat(
    ["localhost", "server.dc1.consul", "consul.service.consul"],
    [for s in keys(local.consul_servers) : "${s}.${var.local_cluster_domain}"]
  )
  ip_addresses    = concat(["127.0.0.1"], values(local.consul_servers))

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "tls_locally_signed_cert" "consul" {
  cert_request_pem   = tls_cert_request.consul.cert_request_pem
  ca_private_key_pem = tls_self_signed_cert.nomad_cluster.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_cluster.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "any_extended",
    "key_encipherment",
    "data_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

resource "local_file" "consul_private_key" {
  filename = "${path.module}/.tmp/certs/consul/private_key.pem"
  content  = tls_private_key.consul.private_key_pem
}

resource "local_file" "consul_public_key" {
  filename = "${path.module}/.tmp/certs/consul/public_key.pem"
  content  = tls_private_key.consul.public_key_pem
}

resource "local_file" "consul_cert" {
  filename = "${path.module}/.tmp/certs/consul/cert.pem"
  content  = tls_locally_signed_cert.consul.cert_pem
}

# Vault
resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "vault" {
  private_key_pem = tls_private_key.vault.private_key_pem
  dns_names       = concat(
    ["localhost", "vault.service.consul", "active.vault.service.consul", "standby.vault.service.consul"],
    [for s in keys(local.vault_servers) : "${s}.${var.local_cluster_domain}"]
  )
  ip_addresses    = concat(["127.0.0.1"], values(local.vault_servers))

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem   = tls_cert_request.vault.cert_request_pem
  ca_private_key_pem = tls_self_signed_cert.nomad_cluster.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_cluster.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "any_extended",
    "key_encipherment",
    "data_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

resource "local_file" "vault_private_key" {
  filename = "${path.module}/.tmp/certs/vault/private_key.pem"
  content  = tls_private_key.vault.private_key_pem
}

resource "local_file" "vault_public_key" {
  filename = "${path.module}/.tmp/certs/vault/public_key.pem"
  content  = tls_private_key.vault.public_key_pem
}

resource "local_file" "vault_cert" {
  filename = "${path.module}/.tmp/certs/vault/cert.pem"
  content  = tls_locally_signed_cert.vault.cert_pem
}

# Nomad Server
resource "tls_private_key" "nomad_server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "nomad_server" {
  private_key_pem = tls_private_key.nomad_server.private_key_pem
  dns_names       = concat(
    ["localhost", "server.global.nomad", "nomad.service.consul"],
    [for s in keys(local.nomad_servers) : "${s}.${var.local_cluster_domain}"]
  )
  ip_addresses    = concat(["127.0.0.1"], values(local.nomad_servers))

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "tls_locally_signed_cert" "nomad_server" {
  cert_request_pem   = tls_cert_request.nomad_server.cert_request_pem
  ca_private_key_pem = tls_self_signed_cert.nomad_cluster.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_cluster.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "any_extended",
    "key_encipherment",
    "data_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

resource "local_file" "nomad_server_private_key" {
  filename = "${path.module}/.tmp/certs/nomad/server/private_key.pem"
  content  = tls_private_key.nomad_server.private_key_pem
}

resource "local_file" "nomad_public_key" {
  filename = "${path.module}/.tmp/certs/nomad/server/public_key.pem"
  content  = tls_private_key.nomad_server.public_key_pem
}

resource "local_file" "nomad_cert" {
  filename = "${path.module}/.tmp/certs/nomad/server/cert.pem"
  content  = tls_locally_signed_cert.nomad_server.cert_pem
}

# Nomad Client
resource "tls_private_key" "nomad_client" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "nomad_client" {
  private_key_pem = tls_private_key.nomad_client.private_key_pem
  # dns_names       = concat(["localhost", "client.global.nomad"], [for s in keys(local.nomad_clients) : "${s}.${var.local_cluster_domain}"])
  # ip_addresses    = concat(["127.0.0.1"], values(local.nomad_clients))
  dns_names = ["localhost", "client.global.nomad", "nomad-client.service.consul"]
  ip_addresses = ["127.0.0.1"]

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "tls_locally_signed_cert" "nomad_client" {
  cert_request_pem   = tls_cert_request.nomad_client.cert_request_pem
  ca_private_key_pem = tls_self_signed_cert.nomad_cluster.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_cluster.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "any_extended",
    "key_encipherment",
    "data_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth",
  ]
}

resource "local_file" "nomad_client_private_key" {
  filename = "${path.module}/.tmp/certs/nomad/client/private_key.pem"
  content  = tls_private_key.nomad_client.private_key_pem
}

resource "local_file" "nomad_client_public_key" {
  filename = "${path.module}/.tmp/certs/nomad/client/public_key.pem"
  content  = tls_private_key.nomad_client.public_key_pem
}

resource "local_file" "nomad_client_cert" {
  filename = "${path.module}/.tmp/certs/nomad/client/cert.pem"
  content  = tls_locally_signed_cert.nomad_client.cert_pem
}
