locals {
  dns_servers = {
    for i in [1, 2] : "dns-server${i}" => "10.99.0.${i + 1}"
  }
  consul_servers = {
    for i in [1, 2, 3] : "consul-server${i}" => "10.99.0.1${i}"
  }
  vault_servers = {
    for i in [1, 2, 3] : "vault-server${i}" => "10.99.0.2${i}"
  }
  nomad_servers = {
    for i in [1, 2, 3] : "nomad-server${i}" => "10.99.0.3${i}"
  }
  nomad_infra_clients = {
    for i in [1, 2] : "nomad-infra-client${i}" => "10.99.0.10${i}"
  }
  nomad_apps_clients = {
    for i in [1, 2, 3] : "nomad-apps-client${i}" => "10.99.0.12${i}"
  }
  nfs_server    = { name = "nfs-server", host = "10.99.0.200" }
  load_balancer = { name = "load-balancer", host = "10.99.0.250" }
}

locals {
  nomad_clients = merge(local.nomad_infra_clients, local.nomad_apps_clients)

  all_servers = merge(
    local.dns_servers,
    local.consul_servers,
    local.vault_servers,
    local.nomad_servers,
    local.nomad_infra_clients,
    local.nomad_apps_clients,
    {
      (local.nfs_server.name)    = local.nfs_server.host
      (local.load_balancer.name) = local.load_balancer.host
    }
  )
}
