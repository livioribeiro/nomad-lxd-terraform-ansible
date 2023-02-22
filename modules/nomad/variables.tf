variable "nfs_server_host" {
  type = string
}

variable "external_domain" {
  type = string
}

variable "apps_subdomain" {
  type = string
}

variable "ca_cert" {
  type = string
}

variable "nomad_autoscaler_cert" {
  type = string
}

variable "nomad_autoscaler_private_key" {
  type = string
}
