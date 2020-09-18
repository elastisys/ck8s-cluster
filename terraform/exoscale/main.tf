terraform {
  backend "remote" {}
}

provider "exoscale" {
  version = "~> 0.12"
  key     = var.exoscale_api_key
  secret  = var.exoscale_secret_key

  timeout = 120 # default: waits 60 seconds in total for a resource
}

module "service_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc

  machines = var.machines_sc

  nfs_size = var.nfs_size

  dns_suffix = "a1ck.io"
  dns_prefix = var.dns_prefix
  dns_list = [
    "*.ops",
    "grafana",
    "harbor",
    "kibana",
    "dex",
    "notary.harbor"
  ]

  ssh_pub_key = var.ssh_pub_key_sc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist
}


module "workload_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc

  machines = var.machines_wc

  nfs_size = var.nfs_size

  dns_suffix = "a1ck.io"
  dns_prefix = var.dns_prefix
  dns_list = [
    "*",
    "prometheus.ops"
  ]

  ssh_pub_key = var.ssh_pub_key_wc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist
}
