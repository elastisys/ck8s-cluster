terraform {
  backend "remote" {}
}

provider "azurerm" {
  version = "=2.25.0"

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  features {}
}

module "service_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc

  machines = var.machines_sc

  compute_instance_image = var.compute_instance_image

  dns_suffix = "elastisys-azure.com"
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

  compute_instance_image = var.compute_instance_image

  dns_suffix = "elastisys-azure.com"
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
