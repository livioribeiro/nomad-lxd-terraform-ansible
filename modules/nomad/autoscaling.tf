resource "nomad_namespace" "system_autoscaling" {
  name = "system-autoscaling"
}

resource "nomad_job" "autoscaler" {
  jobspec = file("${path.module}/jobs/autoscaler.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_autoscaling.name
    }
  }
}