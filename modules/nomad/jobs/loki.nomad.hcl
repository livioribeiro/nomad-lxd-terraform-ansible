variable "version" {
  type    = string
  default = "2.7.2"
}

variable "namespace" {
  type    = string
  default = "system-monitoring"
}

job "loki" {
  datacenters = ["infra", "apps"]
  type        = "service"
  namespace   = var.namespace

  group "loki" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 3100
      }

      port "grpc" {
        to = 9095
      }
    }
    
    service {
      name = "logging-loki"
      port = "3100"

      connect {
        sidecar_service {}

        sidecar_task {
          resources {
            cpu    = 50
            memory = 50
          }
        }
      }

      check {
        name     = "Healthiness Check"
        type     = "http"
        port     = "http"
        path     = "/ready"
        interval = "10s"
        timeout  = "5s"

        check_restart {
          grace = "10s"
          limit = 5
        }
      }

      check {
        name      = "Readiness Check"
        type      = "http"
        port      = "http"
        path      = "/ready"
        interval  = "10s"
        timeout   = "5s"
        on_update = "ignore_warnings"

        check_restart {
          grace = "5s"
          ignore_warnings = true
        }
      }
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:${var.version}"
        args = ["-config.file=/etc/loki/config.yaml"]
        ports = ["http", "grpc"]

        volumes = [
          "local/config.yaml:/etc/loki/config.yaml",
        ]

        logging {
          type = "json-file"
        }
      }

      resources {
        cpu    = 200
        memory = 256
      }

      template {
        destination = "local/config.yaml"

        data = <<EOT
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095

common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093

# By default, Loki will send anonymous, but uniquely-identifiable usage and configuration
# analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/
#
# Statistics help us better understand how Loki is used, and they show us performance
# levels for most users. This helps us prioritize features and documentation.
# For more information on what's sent, look at
# https://github.com/grafana/loki/blob/main/pkg/usagestats/stats.go
# Refer to the buildReport method to see what goes into a report.
#
# If you would like to disable reporting, uncomment the following lines:
#analytics:
#  reporting_enabled: false
EOT
      }
    }
  }
}