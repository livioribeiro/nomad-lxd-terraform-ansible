module "ansible" {
  source = "./ansible"

  ubuntu_version      = var.ubuntu_version
  dns_servers         = [for name, addr in local.dns_servers : { name = name, host = addr }]
  consul_servers      = [for name, addr in local.consul_servers : { name = name, host = addr }]
  vault_servers       = [for name, addr in local.vault_servers : { name = name, host = addr }]
  nomad_servers       = [for name, addr in local.nomad_servers : { name = name, host = addr }]
  nomad_infra_clients = [for name, addr in local.nomad_infra_clients : { name = name, host = addr }]
  nomad_apps_clients  = [for name, addr in local.nomad_apps_clients : { name = name, host = addr }]
  nfs_server          = local.nfs_server
  load_balancer       = local.load_balancer
}

resource "local_file" "nomad_root_token" {
  content = module.ansible.nomad_secret_id
  filename = "${path.module}/root-token-nomad.txt"
}

resource "local_file" "vault_root_token" {
  content = module.ansible.vault_root_token
  filename = "${path.module}/root-token-vault.txt"
}

module "nomad" {
  source = "./nomad"

  nomad_address   = "http://${local.nomad_servers["nomad-server1"]}:4646"
  nomad_secret_id = module.ansible.nomad_secret_id
  # vault_address   = "http://${local.vault_servers["vault-server1"]}:8200"
  # vault_token     = module.ansible.vault_root_token
  nfs_server_host = local.nfs_server.host
}