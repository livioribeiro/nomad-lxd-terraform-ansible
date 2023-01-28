resource "tls_private_key" "cluster_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_public_key" {
  filename = "./ssh/id_rsa.pub"
  content = tls_private_key.cluster_ssh.public_key_pem
}

resource "local_sensitive_file" "ssh_private_key" {
  filename = "./ssh/id_rsa"
  content = tls_private_key.cluster_ssh.private_key_pem
}
