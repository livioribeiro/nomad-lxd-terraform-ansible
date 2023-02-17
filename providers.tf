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

provider "consul" {
  address = "${lxd_container.consul_server["consul-server1"].ipv4_address}:8501"
  scheme  = "https"
  token   = local.consul_management_token
  ca_pem  = tls_self_signed_cert.nomad_cluster.cert_pem
}

# Nomad
data "local_file" "nomad_root_token" {
  depends_on = [null_resource.provision_nomad_server]

  filename   = "${path.module}/.tmp/root_token_nomad.txt"
}

provider "nomad" {
  address   = "https://${lxd_container.nomad_server["nomad-server1"].ipv4_address}:4646"
  secret_id = data.local_file.nomad_root_token.content
  ca_pem    = tls_self_signed_cert.nomad_cluster.cert_pem
}
