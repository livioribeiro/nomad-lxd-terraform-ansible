# resource "nomad_namespace" "system_waypoint" {
#   depends_on = [
#     module.nomad,
#   ]

#   name = "system-waypoint"
# }

# resource "nomad_external_volume" "wp_server" {
#   depends_on = [
#     module.nomad,
#   ]

#   type         = "csi"
#   plugin_id    = "nfs"
#   volume_id    = "wp-server-vol"
#   name         = "wp-server-vol"
#   namespace    = nomad_namespace.system_waypoint.name
#   capacity_min = "500MiB"
#   capacity_max = "800MiB"

#   capability {
#     access_mode     = "single-node-writer"
#     attachment_mode = "file-system"
#   }
# }

# resource "nomad_external_volume" "wp_runner" {
#   depends_on = [
#     module.nomad,
#   ]

#   type         = "csi"
#   plugin_id    = "nfs"
#   volume_id    = "wp-runner-vol"
#   name         = "wp-runner-vol"
#   namespace    = nomad_namespace.system_waypoint.name
#   capacity_min = "500MiB"
#   capacity_max = "800MiB"

#   capability {
#     access_mode     = "multi-node-multi-writer"
#     attachment_mode = "file-system"
#   }
# }

# resource "null_resource" "install_waypoint" {
#   depends_on = [
#     module.nomad,
#   ]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.cluster_ssh.private_key_pem
#     host        = lxd_container.nomad_server["nomad-server1"].ipv4_address
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-get install -y waypoint",
#       <<EOT
# NOMAD_ADDR=https://localhost:4646 \
# NOMAD_TOKEN=${data.local_file.nomad_root_token.content} \
# NOMAD_CAPATH=/etc/certs.d/ca.pem \
# NOMAD_CLIENT_CERT=/etc/certs.d/cert.pem \
# NOMAD_CLIENT_KEY=/etc/certs.d/private_key.pem \
# NOMAD_NAMESPACE=${nomad_namespace.system_waypoint.name} \
# waypoint install -platform=nomad -accept-tos \
#   -nomad-csi-volume-provider=csi \
#   -nomad-csi-plugin-id=nfs \
#   -nomad-csi-fs=ext4 \
#   -nomad-csi-volume=wp-server-vol \
#   -nomad-dc=infra \
#   -nomad-host=https://nomad.service.consul:4646 \
#   -nomad-runner-csi-volume-provider=csi \
#   -nomad-runner-csi-volume=wp-runner-vol \
#   -nomad-runner-csi-volume-provider=nfs \
#   -nomad-consul-service-ui-tags=traefik.enable=true \
#   -nomad-service-ui-tags=traefik.enable=true \
#   -- \
#   -listen-http=0.0.0.0:9702 \
#   -listen-http-insecure=0.0.0.0:9703
#       EOT
#     ]
#   }
# }
