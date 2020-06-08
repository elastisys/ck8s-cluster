terraform {
  backend "remote" {}
  required_providers {
    openstack = ">= 1.28.0"
  }
}

provider "openstack" {
  use_octavia = true
}

locals {
  # Base image used to provision master and worker instances
  compute_instance_image = "CK8S-BaseOS-v0.0.6"
}

data "openstack_images_image_v2" "cluster_image" {
  name        = local.compute_instance_image
  most_recent = true
}

module "service_cluster" {
  source = "./modules/cluster"

  prefix = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc

  ssh_pub_key = var.ssh_pub_key_sc

  cluster_image = data.openstack_images_image_v2.cluster_image.id

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist

  external_network_id   = var.external_network_id
  external_network_name = var.external_network_name

  master_names                = var.master_names_sc
  master_name_flavor_map      = var.master_name_flavor_map_sc
  master_anti_affinity_policy = var.master_anti_affinity_policy_sc

  worker_names                = var.worker_names_sc
  worker_name_flavor_map      = var.worker_name_flavor_map_sc
  worker_anti_affinity_policy = var.worker_anti_affinity_policy_sc

  dns_prefix = var.dns_prefix
  dns_list = [
    "*.ops",
    "grafana",
    "harbor",
    "dex",
    "kibana",
    "notary.harbor"
  ]
  aws_dns_zone_id  = var.aws_dns_zone_id
  aws_dns_role_arn = var.aws_dns_role_arn
}

module "workload_cluster" {
  source = "./modules/cluster"

  prefix = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc

  ssh_pub_key = var.ssh_pub_key_wc

  cluster_image = data.openstack_images_image_v2.cluster_image.id

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist

  external_network_id   = var.external_network_id
  external_network_name = var.external_network_name

  master_names                = var.master_names_wc
  master_name_flavor_map      = var.master_name_flavor_map_wc
  master_anti_affinity_policy = var.master_anti_affinity_policy_wc

  worker_names                = var.worker_names_wc
  worker_name_flavor_map      = var.worker_name_flavor_map_wc
  worker_anti_affinity_policy = var.worker_anti_affinity_policy_wc

  dns_prefix = var.dns_prefix
  dns_list = [
    "*",
    "prometheus.ops"
  ]
  aws_dns_zone_id  = var.aws_dns_zone_id
  aws_dns_role_arn = var.aws_dns_role_arn
}
