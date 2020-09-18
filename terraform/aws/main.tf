terraform {
  backend "remote" {}
}

locals {
  prefix_sc = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc
  prefix_wc = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc
}

provider "aws" {
  version    = "~> 2.50"
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "service_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = local.prefix_sc

  aws_region = var.region

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist

  ssh_pub_key = var.ssh_pub_key_sc

  machines = var.machines_sc
}

module "workload_cluster" {
  source = "./modules/kubernetes-cluster"

  prefix = local.prefix_wc

  aws_region = var.region

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist

  ssh_pub_key = var.ssh_pub_key_wc

  machines = var.machines_wc
}
