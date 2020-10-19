terraform {
  backend "remote" {}
  required_providers {
    openstack = ">= 1.28.0"
  }
}

module "service_cluster" {
  source = "./modules/cluster"

  prefix = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc

  ssh_pub_key = var.ssh_pub_key_sc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist

  external_network_id   = var.external_network_id
  external_network_name = var.external_network_name

  machines = var.machines_sc

  master_anti_affinity_policy = var.master_anti_affinity_policy_sc
  worker_anti_affinity_policy = var.worker_anti_affinity_policy_sc
}

module "workload_cluster" {
  source = "./modules/cluster"

  prefix = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc

  ssh_pub_key = var.ssh_pub_key_wc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist

  external_network_id   = var.external_network_id
  external_network_name = var.external_network_name

  machines = var.machines_wc

  master_anti_affinity_policy = var.master_anti_affinity_policy_wc
  worker_anti_affinity_policy = var.worker_anti_affinity_policy_wc
}
