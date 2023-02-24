variable "ubuntu_version" {
  type    = string
  default = "jammy"
}

variable "external_domain" {
  type    = string
  default = "nomad.localhost"
}

variable "apps_subdomain" {
  type    = string
  default = "apps"
}
