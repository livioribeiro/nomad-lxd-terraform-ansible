locals {
  nomad_acl_bootstrap = jsondecode(data.local_file.nomad_acl_bootstrap.content)
  vault_init          = jsondecode(data.local_file.vault_init.content)
}

output "nomad_acl_bootstrap" {
  value = local.nomad_acl_bootstrap
}

output "nomad_secret_id" {
  value = local.nomad_acl_bootstrap.SecretID
}

output "vault_init" {
  value = local.vault_init
}

output "vault_root_token" {
  value = local.vault_init.root_token
}