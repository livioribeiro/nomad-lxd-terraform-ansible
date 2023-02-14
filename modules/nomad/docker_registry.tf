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