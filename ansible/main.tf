resource "local_file" "inventory" {
  filename = "${path.module}/inventory/hosts"
  content = <<-EOT
    [dns_servers]
    %{ for server in var.dns_servers ~}
    ${~ server.name} ansible_host=${server.host}
    %{ endfor ~}

    [consul_servers]
    %{ for server in var.consul_servers ~}
    ${~ server.name} ansible_host=${server.host}
    %{ endfor ~}

    [vault_servers]
    %{ for server in var.vault_servers ~}
    ${~ server.name} ansible_host=${server.host}
    %{ endfor ~}

    [nomad_servers]
    %{ for server in var.nomad_servers ~}
    ${~ server.name} ansible_host=${server.host}
    %{ endfor ~}

    [nomad_infra_clients]
    %{ for server in var.nomad_infra_clients ~}
    ${~ server.name} ansible_host=${server.host}
    %{ endfor ~}

    [nomad_apps_clients]
    %{ for server in var.nomad_apps_clients ~}
    ${~ server.name} ansible_host=${server.host}
    %{ endfor ~}

    [nomad_clients:children]
    nomad_infra_clients
    nomad_apps_clients

    [cluster]
    ${var.nfs_server.name} ansible_host=${var.nfs_server.host}
    ${var.load_balancer.name} ansible_host=${var.load_balancer.host}

    [cluster:children]
    dns_servers
    consul_servers
    vault_servers
    nomad_servers
    nomad_clients
  EOT
}

# data "local_file" "inventory" {
#   filename = "${path.module}/inventory/hosts"
# }

resource "null_resource" "ansible" {
  depends_on = [
    local_file.inventory
  ]

  provisioner "local-exec" {
    working_dir = path.module
    command = <<-EOT
      ansible-playbook playbook.yml
    EOT
  }
}

data "local_file" "nomad_acl_bootstrap" {
  filename   = "${path.module}/nomad_acl_bootstrap.json"
  depends_on =[null_resource.ansible]
}

data "local_file" "vault_init" {
  filename   = "${path.module}/vault_init.json"
  depends_on =[null_resource.ansible]
}
