module "packer" {
  source = "./modules/packer"

  ssh_key = tls_private_key.cluster_ssh.public_key_openssh
}

module "nomad" {
  source = "./modules/nomad"

  depends_on = [
    null_resource.provision_nomad_server,
    null_resource.provision_nomad_client,
    null_resource.provision_nfs_server,
  ]

  nfs_server_host = "nfs-server.cluster.local"
  external_domain = var.external_domain
  apps_subdomain  = var.apps_subdomain
}
