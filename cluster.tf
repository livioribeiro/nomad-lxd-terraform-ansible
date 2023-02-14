resource "lxd_network" "nomad" {
  name = "lxdnomadbr0"
  type = "bridge"

  config = {
    "ipv4.address" = "10.99.0.1/24"
    "ipv4.nat"     = true
    "ipv4.dhcp"    = false
    "ipv6.address" = "none"
  }
}

resource "lxd_profile" "nomad" {
  name = "nomad"

  device {
    type = "nic"
    name = "eth0"

    properties = {
      network = lxd_network.nomad.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }
}
