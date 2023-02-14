variable "version" {
  type    = string
  default = "2"
}

variable "namespace" {
  type    = string
  default = "system-registry"
}

job "docker-registry" {
  datacenters = ["infra", "apps"]
  type        = "service"
  namespace   = var.namespace

  group "registry" {
    count = 1

    network {
      port "docker" {
        static = 5000
      }
    }

    service {
      name = "docker-registry"
      port = "docker"
      tags = ["traefik.enable=true"]
    }

    task "registry" {
      driver = "docker"

      config {
        image = "registry:${var.version}"
        ports = ["docker"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}