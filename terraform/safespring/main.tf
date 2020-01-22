terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "elastisys"

    workspaces {
      prefix = "safespring-demo-"
    }
  }
}

provider "openstack" {
  project_domain_name = "elastisys.se"
  user_domain_name    = "elastisys.se"
  tenant_name         = "infra.elastisys.se"
  auth_url            = "https://keystone.api.cloud.ipnett.se/v3"
  region              = "se-east-1"
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "ubuntu-18.04-server-cloudimg-amd64-20190212.1"
  most_recent = true
}

resource "openstack_compute_keypair_v2" "sshkey_sc" {
  name       = "${terraform.workspace}-ssh-key-sc"
  public_key = file(pathexpand(var.ssh_pub_key_file_sc))
}

resource "openstack_compute_keypair_v2" "sshkey_wc" {
  name       = "${terraform.workspace}-ssh-key-wc"
  public_key = file(pathexpand(var.ssh_pub_key_file_wc))
}

module "service_cluster" {
  source = "./modules/kubernetes-cluster"
  prefix = "${terraform.workspace}-service-cluster"
  
  public_v4_network        = var.public_v4_network
  worker_names             = var.worker_names_sc
  worker_name_flavor_map   = var.worker_name_flavor_map_sc
  worker_extra_volume      = var.worker_extra_volume_sc
  worker_extra_volume_size = var.worker_extra_volume_size_sc

  master_names           = var.master_names_sc
  master_name_flavor_map = var.master_name_flavor_map_sc

  image_id = data.openstack_images_image_v2.ubuntu.id
  key_pair = openstack_compute_keypair_v2.sshkey_sc.id

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

  prefix = "${terraform.workspace}-workload-cluster"

  public_v4_network        = var.public_v4_network
  worker_names             = var.worker_names_wc
  worker_name_flavor_map   = var.worker_name_flavor_map_wc
  worker_extra_volume      = var.worker_extra_volume_wc
  worker_extra_volume_size = var.worker_extra_volume_size_wc

  image_id = data.openstack_images_image_v2.ubuntu.id
  key_pair = openstack_compute_keypair_v2.sshkey_wc.id

  dns_list = [
    "*.${var.dns_prefix}",
    "prometheus.ops.${var.dns_prefix}"
  ]

  master_names           = var.master_names_wc
  master_name_flavor_map = var.master_name_flavor_map_wc
}
