locals {
  image_consul = "local:consul"
}

resource "null_resource" "image_consul" {
  depends_on = [null_resource.image_base]

  triggers = {
    template = sha256(file("${path.module}/packer/consul.pkr.hcl"))
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/packer"
    command     = "packer build -var image_source=${local.image_base} consul.pkr.hcl"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "lxc image delete local:consul"
  }
}
