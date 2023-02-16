variable "version" {
  type    = string
  default = "v2.42.0"
}

variable "namespace" {
  type    = string
  default = "system-monitoring"
}

variable "consul_acl_token" {
  type    = string
  default = ""
}

variable "vault_token" {
  type    = string
  default = ""
}

job "metrics" {
  datacenters = ["infra", "apps"]
  type        = "service"
  namespace   = var.namespace

  group "prometheus" {
    count = 1

    network {
      port "prometheus" {
        static = 9090
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:${var.version}"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]

        ports = ["prometheus"]
      }

      service {
        name = "prometheus"
        tags = ["traefik.enable=true"]
        port = "prometheus"

        check {
          name     = "prometheus port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        destination = "local/prometheus.yml"

        data = <<EOT
# Source:
# https://learn.hashicorp.com/tutorials/nomad/prometheus-metrics
---

global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:
  # CONSUL
  - job_name: consul_metrics
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      token: '${var.consul_acl_token}'
      services: [consul]

    scrape_interval: 5s
    metrics_path: /v1/agent/metrics
    scheme: https
    params:
      format: [prometheus]

    tls_config:
      insecure_skip_verify: true

    relabel_configs:
    - source_labels: [__address__]
      regex: '(.+):8300'
      target_label: __address__
      replacement: $${1}:8501

  # VAULT
  - job_name: vault_metrics
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      token: '${var.consul_acl_token}'
      services: [vault]
      tags: [active]

    scrape_interval: 5s
    metrics_path: /v1/sys/metrics
    scheme: https
    params:
      format: [prometheus]

    tls_config:
      insecure_skip_verify: true

  # NOMAD
  - job_name: nomad_metrics
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      token: '${var.consul_acl_token}'
      services: [nomad-client, nomad]

    tls_config:
      insecure_skip_verify: true

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    scheme: https
    params:
      format: [prometheus]

  # NOMAD AUTOSCALER
  - job_name: nomad_autoscaler
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      token: '${var.consul_acl_token}'
      services: [autoscaler]

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: [prometheus]

  # PROXY/TRAEFIK
  - job_name: proxy_metrics
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      token: '${var.consul_acl_token}'
      services: [proxy]

  # CONSUL CONNECT ENVOY STATSD
  - job_name: consul_connect_statsd_envoy_metrics
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      token: '${var.consul_acl_token}'
      services: [statsd]

  # CONSUL CONNECT ENVOY
  # https://www.mattmoriarity.com/2021-02-21-scraping-prometheus-metrics-with-nomad-and-consul-connect/
  - job_name: consul_connect_envoy_metrics
    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
        token: '${var.consul_acl_token}'

    relabel_configs:
    - source_labels: [__meta_consul_service]
      action: drop
      regex: (.+)-sidecar-proxy
    - source_labels: [__meta_consul_service_metadata_envoy_metrics_port]
      action: keep
      regex: (.+)
    - source_labels: [__address__, __meta_consul_service_metadata_envoy_metrics_port]
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $${1}:$${2}
      target_label: __address__
EOT
      }
    }
  }
}