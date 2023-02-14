terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~>3.4"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~>2.3"
    }

    null = {
      source  = "hashicorp/null"
      version = "~>3.2"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~>2.3"
    }

    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~>1.9"
    }

    consul = {
      source  = "hashicorp/consul"
      version = "~>2.17"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~>3.12"
    }

    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 1.4"
    }
  }
}

provider "lxd" {
  accept_remote_certificate    = true
  generate_client_certificates = true
}

# Consul
data "local_file" "consul_root_token" {
  depends_on = [null_resource.provision_consul_server]

  filename = "${path.module}/root_token_consul.txt"
}

provider "consul" {
  address = "${lxd_container.consul_server["consul-server1"].ipv4_address}:8501"
  scheme  = "https"
  token   = data.local_file.consul_root_token.content
  ca_pem  = tls_self_signed_cert.nomad_cluster.cert_pem
}

/*
# Vault
data "local_file" "vault_root_token" {
  depends_on = [null_resource.provision_vault_server]
  filename = "${path.module}/root_token_vault.txt"
}

provider "vault" {
  address      = "${lxd_container.vault_server["vault-server1"].ipv4_address}:8200"
  token        = data.local_file.vault_root_token.content
  ca_cert_dir  = "${path.module}/certs"
}
*/

# Nomad
data "local_file" "nomad_root_token" {
  depends_on = [null_resource.provision_nomad_server]
  filename   = "${path.module}/root_token_nomad.txt"
}

provider "nomad" {
  address   = "https://${lxd_container.nomad_server["nomad-server1"].ipv4_address}:4646"
  secret_id = data.local_file.nomad_root_token.content
  ca_pem    = tls_self_signed_cert.nomad_cluster.cert_pem
}
