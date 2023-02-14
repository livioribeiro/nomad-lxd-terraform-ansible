# Prometheus Consul ACL
resource "consul_acl_policy" "prometheus" {
  name  = "prometheus"
  rules = <<-EOT
    agent_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "read"
    }

    service_prefix "prometheus" {
      policy = "write"
    }
  EOT
}
resource "consul_acl_role" "prometheus" {
  name        = "prometheus"
  description = "prometheus role"

  policies = [
    "${consul_acl_policy.prometheus.id}"
  ]
}

resource "consul_acl_token" "prometheus" {
  description = "prometheus acl token"
  roles       = [consul_acl_role.prometheus.name]
  local       = true
}

data "consul_acl_token_secret_id" "prometheus" {
  accessor_id = consul_acl_token.prometheus.id
}

resource "nomad_namespace" "system_monitoring" {
  name = "system-monitoring"
}

resource "nomad_job" "prometheus" {
  jobspec = file("${path.module}/jobs/prometheus.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace        = nomad_namespace.system_monitoring.name
      consul_acl_token = data.consul_acl_token_secret_id.prometheus.secret_id
    }
  }
}

resource "nomad_job" "stats_exporter" {
  jobspec = file("${path.module}/jobs/statsd-exporter.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_monitoring.name
    }
  }
}