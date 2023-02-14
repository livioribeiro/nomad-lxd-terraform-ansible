terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }

    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}