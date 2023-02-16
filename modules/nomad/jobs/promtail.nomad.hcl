variable "version" {
  type    = string
  default = "2.7.2"
}

variable "namespace" {
  type    = string
  default = "system-monitoring"
}

job "promtail" {
  datacenters = ["infra", "apps"]
  type        = "system"
  namespace   = var.namespace

  group "promtail" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 8080
      }

      port "grpc" {
        to = 9095
      }
    }
    
    service {
      name = "logging-promtail"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "logging-loki"
              local_bind_port  = 3100
            }
          }
        }
        sidecar_task {
          resources {
            cpu    = 50
            memory = 50
          }
        }
      }
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/promtail:${var.version}"
        args = ["-config.file=/etc/promtail/config.yaml"]
        ports = ["http", "grpc"]

        volumes = [
          "local/config.yaml:/etc/promtail/config.yaml",
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }

      resources {
        cpu    = 200
        memory = 256
      }

      template {
        destination = "local/config.yaml"

        data = <<EOT
server:
  http_listen_port: 8080
  grpc_listen_port: 9095

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://{{ env "NOMAD_UPSTREAM_ADDR_logging_loki" }}/loki/api/v1/push

scrape_configs:
- job_name: docker-logs
  docker_sd_configs:
    - host: unix:///var/run/docker.sock
      refresh_interval: 5s
  pipeline_stages:
    - docker: {}
  relabel_configs:
    - source_labels: ['__meta_docker_container_name']
      regex: '/(.*)'
      target_label: 'container'
    - source_labels: ['__meta_docker_container_log_stream']
      target_label: 'log_stream'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_alloc_id']
      target_label: 'nomad_alloc_id'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_job_name']
      target_label: 'nomad_job_name'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_job_id']
      target_label: 'nomad_job_id'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_task_group_name']
      target_label: 'nomad_task_group'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_task_name']
      target_label: 'nomad_task'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_namespace']
      target_label: 'nomad_namespace'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_node_name']
      target_label: 'nomad_node_name'
    - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_node_id']
      target_label: 'nomad_node_id'
EOT
      }
    }
  }
}