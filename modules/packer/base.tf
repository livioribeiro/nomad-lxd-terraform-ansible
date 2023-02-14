resource "lxd_cached_image" "ubuntu_base" {
  source_remote = "images"
  source_image  = "ubuntu/${var.ubuntu_version}/cloud"
}

locals {
  image_base        = "local:base"
  image_base_source = lxd_cached_image.ubuntu_base.fingerprint
}

resource "null_resource" "image_base" {
  triggers = {
    template = sha256(file("${path.module}/packer/base.pkr.hcl"))
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/packer"
    command     = "packer build -var image_source=${local.image_base_source} -var ssh_key='${var.ssh_key}' base.pkr.hcl"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "lxc image delete local:base"
  }
}
