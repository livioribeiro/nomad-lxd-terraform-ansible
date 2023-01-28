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

    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~>1.9"
    }
  }
}

provider "lxd" {
  accept_remote_certificate    = true
  generate_client_certificates = true
}
