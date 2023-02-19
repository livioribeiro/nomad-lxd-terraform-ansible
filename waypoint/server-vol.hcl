id        = "wp-server-vol" # ID as seen in nomad
name      = "wp-server-vol" # Display name
type      = "csi"
plugin_id = "nfs" # Needs to match the deployed plugin

capability {
  access_mode     = "multi-node-multi-writer"
  attachment_mode = "file-system"
}
