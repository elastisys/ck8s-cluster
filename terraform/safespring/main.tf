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

data "openstack_compute_flavor_v2" "b_small" {
  vcpus = 1
  ram   = 2048
}

data "openstack_compute_flavor_v2" "b_medium" {
  vcpus = 2
  ram   = 4096
}

data "openstack_compute_flavor_v2" "b_large" {
  vcpus = 4
  ram   = 8192
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

  master_count = var.sc_master_count
  worker_count = var.sc_worker_count

  image_id = data.openstack_images_image_v2.ubuntu.id
  key_pair = openstack_compute_keypair_v2.sshkey_sc.id

  dns_list = [
    "*.ops.${var.dns_prefix}",
    "grafana.${var.dns_prefix}",
    "harbor.${var.dns_prefix}",
    "dex.${var.dns_prefix}",
    "kibana.${var.dns_prefix}"
  ]

  master_flavor_id = data.openstack_compute_flavor_v2.b_medium.id
  worker_flavor_id = data.openstack_compute_flavor_v2.b_large.id
  nfs_flavor_id    = data.openstack_compute_flavor_v2.b_small.id
  nfs_storage_size = 50
}

module "workload_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = "${terraform.workspace}-workload-cluster"

  master_count = var.wc_master_count
  worker_count = var.wc_worker_count

  image_id = data.openstack_images_image_v2.ubuntu.id
  key_pair = openstack_compute_keypair_v2.sshkey_wc.id

  dns_list = [
    "*.${var.dns_prefix}",
    "prometheus.ops.${var.dns_prefix}"
  ]

  master_flavor_id = data.openstack_compute_flavor_v2.b_medium.id
  worker_flavor_id = data.openstack_compute_flavor_v2.b_large.id
  nfs_flavor_id    = data.openstack_compute_flavor_v2.b_small.id
  nfs_storage_size = 50
}
