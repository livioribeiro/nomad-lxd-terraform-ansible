locals {
  image_nomad_client = "local:nomad-client"
}

resource "null_resource" "image_nomad_client" {
  depends_on = [null_resource.image_consul]

  triggers = {
    template = sha256(file("${path.module}/packer/nomad-client.pkr.hcl"))
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/packer"
    command     = "packer build -var image_source=${local.image_consul} nomad-client.pkr.hcl"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "lxc image delete local:nomad-client"
  }
}
