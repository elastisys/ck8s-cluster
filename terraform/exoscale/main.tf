terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "elastisys"

    workspaces {
      prefix = "a1-demo-"
    }
  }
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

  worker_names         = var.worker_names_sc
  worker_name_size_map = var.worker_name_size_map_sc
  master_names         = var.master_names_sc
  master_name_size_map = var.master_name_size_map_sc

  compute_instance_image = var.compute_instance_image
  nfs_size               = var.nfs_size

  dns_suffix = "a1ck.io"
  dns_list = [
    "*.ops.${var.dns_prefix}",
    "grafana.${var.dns_prefix}",
    "harbor.${var.dns_prefix}",
    "kibana.${var.dns_prefix}",
    "dex.${var.dns_prefix}",
    "notary.harbor.${var.dns_prefix}"
  ]


  ssh_pub_key = var.ssh_pub_key_sc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist

}


module "workload_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc

  worker_names         = var.worker_names_wc
  worker_name_size_map = var.worker_name_size_map_wc
  master_names         = var.master_names_wc
  master_name_size_map = var.master_name_size_map_wc

  compute_instance_image = var.compute_instance_image
  nfs_size               = var.nfs_size

  dns_suffix = "a1ck.io"
  dns_list = [
    "*.${var.dns_prefix}",
    "prometheus.ops.${var.dns_prefix}"
  ]

  ssh_pub_key = var.ssh_pub_key_wc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
}
