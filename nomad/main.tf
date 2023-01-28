# storage
resource "nomad_namespace" "system_storage" {
  name = "system-storage"
}

resource "nomad_job" "rocketduck_nfs_controller" {
  jobspec = file("${path.module}/jobs/rocketduck-nfs/controller.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_storage.name
      nfs_server_host = var.nfs_server_host
    }
  }
}

resource "nomad_job" "rocketduck_nfs_node" {
  jobspec = file("${path.module}/jobs/rocketduck-nfs/node.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_storage.name
      nfs_server_host = var.nfs_server_host
    }
  }
}

data "nomad_plugin" "nfs" {
  depends_on = [
    nomad_job.rocketduck_nfs_controller,
    nomad_job.rocketduck_nfs_node,
  ]

  plugin_id        = "nfs"
  wait_for_healthy = true
}

# gateway
resource "nomad_namespace" "system_gateway" {
  name = "system-gateway"
}

resource "nomad_job" "proxy" {
  jobspec = file("${path.module}/jobs/proxy.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_gateway.name
    }
  }
}

# monitoring
resource "nomad_namespace" "system_monitoring" {
  name = "system-monitoring"
}

resource "nomad_job" "prometheus" {
  jobspec = file("${path.module}/jobs/prometheus.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_monitoring.name
    }
  }
}

# autoscaling
resource "nomad_namespace" "system_autoscaling" {
  name = "system-autoscaling"
}

resource "nomad_job" "autoscaler" {
  jobspec = file("${path.module}/jobs/autoscaler.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_autoscaling.name
    }
  }
}

# docker registry
resource "nomad_namespace" "system_registry" {
  name = "system-registry"
}

resource "nomad_job" "docker-registry" {
  jobspec = file("${path.module}/jobs/docker-registry.nomad")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_registry.name
    }
  }
}

# sso
resource "nomad_namespace" "system_sso" {
  name = "system-sso"
}

resource "nomad_external_volume" "sso_database_data" {
  type        = "csi"
  plugin_id   = "nfs"
  volume_id   = "sso-database-data"
  name        = "sso-database-data"
  namespace   = "system-sso"
  capacity_min = "250MiB"
  capacity_max = "500MiB"

  depends_on = [
    data.nomad_plugin.nfs
  ]

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "sso" {
  jobspec = file("${path.module}/jobs/keycloak.nomad")
  # detach = false

  depends_on = [
    nomad_external_volume.sso_database_data
  ]

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_sso.name
    }
  }
}
