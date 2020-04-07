terraform {
  backend "remote" {}
}

provider "openstack" {
  use_octavia = true
}

data "openstack_images_image_v2" "os_image" {
  name        = var.compute_instance_image
  most_recent = true
}

data "openstack_networking_network_v2" "ext-net" {
  name = "ext-net"
}

resource "openstack_compute_keypair_v2" "sshkey_sc" {
  name       = "${terraform.workspace}-ssh-key-sc"
  public_key = file(pathexpand(var.ssh_pub_key_sc))
}

resource "openstack_compute_keypair_v2" "sshkey_wc" {
  name       = "${terraform.workspace}-ssh-key-wc"
  public_key = file(pathexpand(var.ssh_pub_key_wc))
}

module "service_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc

  public_v4_network      = data.openstack_networking_network_v2.ext-net.id
  worker_names           = var.worker_names_sc
  worker_name_flavor_map = var.worker_name_flavor_map_sc

  master_names           = var.master_names_sc
  master_name_flavor_map = var.master_name_flavor_map_sc

  image_id = data.openstack_images_image_v2.os_image.id
  key_pair = openstack_compute_keypair_v2.sshkey_sc.id

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist

  dns_list = [
    "*.ops.${var.dns_prefix}",
    "grafana.${var.dns_prefix}",
    "harbor.${var.dns_prefix}",
    "dex.${var.dns_prefix}",
    "kibana.${var.dns_prefix}",
    "notary.harbor.${var.dns_prefix}"
  ]

}


module "workload_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc

  public_v4_network      = data.openstack_networking_network_v2.ext-net.id
  worker_names           = var.worker_names_wc
  worker_name_flavor_map = var.worker_name_flavor_map_wc

  image_id = data.openstack_images_image_v2.os_image.id
  key_pair = openstack_compute_keypair_v2.sshkey_wc.id

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist

  dns_list = [
    "*.${var.dns_prefix}",
    "prometheus.ops.${var.dns_prefix}"
  ]

  master_names           = var.master_names_wc
  master_name_flavor_map = var.master_name_flavor_map_wc
}
