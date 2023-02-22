terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~>2.3"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~>3.13"
    }
  }
}

provider "vault" {
  address      = var.vault_addr
  token        = var.vault_token
  ca_cert_file = "../.tmp/certs/ca.pem"
}