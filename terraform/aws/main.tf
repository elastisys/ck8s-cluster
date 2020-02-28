terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "elastisys"

    workspaces {
      prefix = "aws-demo-"
    }
  }
}

provider "aws" {
  version = "~> 2.50"
  region  = var.region
  shared_credentials_file = pathexpand(var.infra_credentials_file_path)
}

module "service_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist

  public_key_path = var.public_key_path
  key_name        = var.sc_key_name

  worker_nodes = var.worker_nodes_sc
  master_nodes = var.master_nodes_sc
}

module "workload_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist

  public_key_path = var.public_key_path
  key_name        = var.wc_key_name

  worker_nodes = var.worker_nodes_wc
  master_nodes = var.master_nodes_wc
}

module "service_dns" {
  source = "../aws-dns"

  credentials_file_path = var.dns_credentials_file_path

  dns_list = [
    "*.ops.${var.dns_prefix}",
    "grafana.${var.dns_prefix}",
    "harbor.${var.dns_prefix}",
    "dex.${var.dns_prefix}",
    "kibana.${var.dns_prefix}",
    "notary.harbor.${var.dns_prefix}"
  ]
  dns_records = module.service_cluster.worker_public_ips
}

module "workload_dns" {
  source = "../aws-dns"

  credentials_file_path = var.dns_credentials_file_path

  dns_list = [
    "*.${var.dns_prefix}",
    "prometheus.ops.${var.dns_prefix}"
  ]
  dns_records = module.workload_cluster.worker_public_ips
}
