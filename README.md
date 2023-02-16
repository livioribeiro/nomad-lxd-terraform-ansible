# Hashicorp Nomad cluster with LXD and Terraform.

Create a nomad cluster for local testing using Terraform and Ansible

- [Nomad](https://www.nomadproject.io/)
- [Consul](https://www.consul.io/)
- [Vault](https://www.vaultproject.io/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Traefik](https://traefik.io/traefik/)
- [LXD](https://linuxcontainers.org/#LXD)
- [Terraform](https://www.terraform.io/)
- [Ansible](https://www.ansible.com/)

The cluster contains the following nodes:

- 2 DNS servers
- 3 Consul nodes
- 3 Vault nodes
- 3 Nomad server nodes
- 5 Nomad client nodes (3 "apps" nodes, 2 "infra" nodes)
- 1 NFS server node
- 1 Load balancer node

Consul is used to bootstrap the Nomad cluster, for service discovery and for the
service mesh.

The client infra nodes are the entrypoint of the cluster. They will run Traefik
and use Consul service catalog to expose the applications.

Load balancer will proxy to the infra nodes.

The proxy configuration exposes the services at `{{ service name }}.apps.nomad.localhost`,
so when you deploy the service [hello.nomad](hello.nomad),
it will be exposed at `hello-world.apps.nomad.localhost`

## NFS and CSI Plugin

For storage with the NFS node, a CSI plugin will be configured using the [RocketDuck CSI plugin](https://gitlab.com/rocketduck/csi-plugin-nfs).


The are also examples of [other CSI plugins](csi_plugins).

## Cluster services

There are several services provided in the cluster:

- [Docker Registry pull through cache](https://docs.docker.com/registry/recipes/mirror/)
- Keycloak
- Prometheus
- Grafana
- [Logging aggregation with Loki and Promtail](https://grafana.com/oss/loki/)
- [Nomad Autoscaler](https://github.com/hashicorp/nomad-autoscaler)
- [statsd_exporter](https://github.com/prometheus/statsd_exporter)
  - To forward consul connect envoy metrics to prometheus

## Examples

There are 3 example jobs:

- [hello.nomad](examples/hello.nomad), a simples hello world
- [countdash.nomad](examples/countdash.nomad), shows the usage of consul connect
- [nfs](examples/nfs/), show how to setup volumes using the nfs csi plugin

