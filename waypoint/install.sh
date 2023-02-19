waypoint install -platform=nomad -accept-tos \
  -nomad-host-volume=wp-server-vol \
  -nomad-runner-host-volume=wp-runner-vol \
  -nomad-csi-plugin-id=nfs \
  -nomad-csi-fs=ext4 \
  -nomad-csi-volume=wp-server-vol \
  -nomad-dc=infra \
  -nomad-host=https://nomad.service.consul:4646 \
  -nomad-runner-csi-volume=wp-runner-vol \
  -nomad-runner-csi-volume-provider=nfs \
  -nomad-consul-service-ui-tags=traefik.enable=true \
  -nomad-service-ui-tags=traefik.enable=true \
  -- \
  -listen-http=0.0.0.0:9702 \
  -listen-http-insecure=0.0.0.0:9703 \
  -tls-cert-file=.tmp/certs/nomad/server/cert.pem \
  -tls-key-file=.tmp/certs/nomad/server/private_key.pem

