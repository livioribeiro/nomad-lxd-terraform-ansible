variable "dns_servers" {
  type = list(object({name = string, host = string}))
}

variable "consul_servers" {
  type = list(object({name = string, host = string}))
}

variable "vault_servers" {
  type = list(object({name = string, host = string}))
}

variable "nomad_servers" {
  type = list(object({name = string, host = string}))
}

variable "nomad_infra_clients" {
  type = list(object({name = string, host = string}))
}

variable "nomad_apps_clients" {
  type = list(object({name = string, host = string}))
}

variable "nfs_server" {
  type = object({name = string, host = string})
}

variable "load_balancer" {
  type = object({name = string, host = string})
}