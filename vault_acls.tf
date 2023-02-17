/*
Vault provider requires a working Vault instance to even execute "terraform plan"

Because of this, I made this workaround to call terraform in another module using
null_resource and local-exec provisioner, so this "virtual sub module" would only
execute after Vault is fully initialized by the "main module".
*/

data "local_file" "vault_root_token" {
  depends_on = [null_resource.provision_vault_server]

  filename = "${path.module}/.tmp/root_token_vault.txt"
}

resource "null_resource" "vault_acls" {
  provisioner "local-exec" {
    working_dir = "vault"
    command     = <<EOT
sleep 30 &&
terraform init && \
terraform apply -auto-approve \
  -var 'vault_addr=https://${lxd_container.vault_server["vault-server1"].ipv4_address}:8200' \
  -var 'vault_token=${data.local_file.vault_root_token.content}'
    EOT
  }

  provisioner "local-exec" {
    working_dir = "vault"
    when        = destroy
    command     = "rm -rf ./.terraform ./.terraform.lock.hcl ./terraform.tfstate ./terraform.tfstate.backup"
  }
}