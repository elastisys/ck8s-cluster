terraform {
  backend "remote" {}
}

provider "openstack" {
  use_octavia = true
}

locals {
  # Base image used to provision master and worker instances
  compute_instance_image = "CK8S-BaseOS-v0.0.5"
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

  external_network_id   = var.external_network_id
  external_network_name = var.external_network_name

  master_names           = var.master_names_sc
  master_name_flavor_map = var.master_name_flavor_map_sc

  worker_names           = var.worker_names_sc
  worker_name_flavor_map = var.worker_name_flavor_map_sc

  octavia_names = var.octavia_names_sc

  dns_list = [
    "*.ops.${var.dns_prefix}",
    "grafana.${var.dns_prefix}",
    "harbor.${var.dns_prefix}",
    "dex.${var.dns_prefix}",
    "kibana.${var.dns_prefix}",
    "notary.harbor.${var.dns_prefix}"
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

  external_network_id   = var.external_network_id
  external_network_name = var.external_network_name

  master_names           = var.master_names_wc
  master_name_flavor_map = var.master_name_flavor_map_wc

  worker_names           = var.worker_names_wc
  worker_name_flavor_map = var.worker_name_flavor_map_wc

  octavia_names = var.octavia_names_wc

  dns_list = [
    "*.${var.dns_prefix}",
    "prometheus.ops.${var.dns_prefix}"
  ]
  aws_dns_zone_id  = var.aws_dns_zone_id
  aws_dns_role_arn = var.aws_dns_role_arn
}