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
  early_renewal_hours = 720
  is_ca_certificate = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_file" "cluster_ca_cert" {
  filename = "${path.module}/certs/ca.pem"
  content = tls_self_signed_cert.nomad_cluster.cert_pem
}

# Consul
resource "tls_private_key" "consul" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "consul" {
  private_key_pem = tls_private_key.consul.private_key_pem

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
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_file" "consul_private_key" {
  filename = "${path.module}/certs/consul/private_key.pem"
  content = tls_private_key.consul.private_key_pem
}

resource "local_file" "consul_public_key" {
  filename = "${path.module}/certs/consul/public_key.pem"
  content = tls_private_key.consul.public_key_pem
}

resource "local_file" "consul_cert" {
  filename = "${path.module}/certs/consul/cert.pem"
  content = tls_locally_signed_cert.consul.cert_pem
}

# Vault
resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "vault" {
  private_key_pem = tls_private_key.vault.private_key_pem

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
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_file" "vault_private_key" {
  filename = "${path.module}/certs/vault/private_key.pem"
  content = tls_private_key.vault.private_key_pem
}

resource "local_file" "vault_public_key" {
  filename = "${path.module}/certs/vault/public_key.pem"
  content = tls_private_key.vault.public_key_pem
}

resource "local_file" "vault_cert" {
  filename = "${path.module}/certs/vault/cert.pem"
  content = tls_locally_signed_cert.vault.cert_pem
}

# Nomad
resource "tls_private_key" "nomad" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "nomad" {
  private_key_pem = tls_private_key.nomad.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "tls_locally_signed_cert" "nomad" {
  cert_request_pem   = tls_cert_request.nomad.cert_request_pem
  ca_private_key_pem = tls_self_signed_cert.nomad_cluster.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_cluster.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_file" "nomad_private_key" {
  filename = "${path.module}/certs/nomad/private_key.pem"
  content = tls_private_key.nomad.private_key_pem
}

resource "local_file" "nomad_public_key" {
  filename = "${path.module}/certs/nomad/public_key.pem"
  content = tls_private_key.nomad.public_key_pem
}

resource "local_file" "nomad_cert" {
  filename = "${path.module}/certs/nomad/cert.pem"
  content = tls_locally_signed_cert.nomad.cert_pem
}