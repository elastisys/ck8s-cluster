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
  source                      = "./modules/kubernetes-cluster"

  master_name                 = "${terraform.workspace}-sc-master"
  master_count                = var.sc_master_count
  master_size                 = var.sc_master_size

  worker_name                 = "${terraform.workspace}-sc-worker"
  worker_count                = "${var.sc_worker_count}"
  worker_size                 = var.sc_worker_size

  nfs_name                    = "${terraform.workspace}-sc-nfs"
  nfs_size                    = var.sc_nfs_size

  network_name                = "${terraform.workspace}-sc-network"
  dns_list                    = [ 
                                  "*.ops.${var.dns_prefix}",
                                  "grafana.${var.dns_prefix}",
                                  "harbor.${var.dns_prefix}",
                                  "kibana.${var.dns_prefix}",
                                  "dex.${var.dns_prefix}"
                                ]

  master_security_group_name  = "${terraform.workspace}-sc-master-sg"
  worker_security_group_name  = "${terraform.workspace}-sc-worker-sg"
  nfs_security_group_name     = "${terraform.workspace}-sc-nfs-sg"

  ssh_key_name                = "${terraform.workspace}-sc-ssh-key"
  ssh_pub_key_file            = var.ssh_pub_key_file_sc
  
  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist

}


module "workload_cluster" {
  source                      = "./modules/kubernetes-cluster"

  master_name                 = "${terraform.workspace}-wc-master"
  master_count                = var.wc_master_count
  master_size                 = var.wc_master_size

  worker_name                 = "${terraform.workspace}-wc-worker"
  worker_count                = var.wc_worker_count
  worker_size                 = var.wc_worker_size

  nfs_name                    = "${terraform.workspace}-wc-nfs"
  nfs_size                    = var.wc_nfs_size

  network_name                = "${terraform.workspace}-wc-network"
  dns_list                   = ["*.${var.dns_prefix}"]

  master_security_group_name  = "${terraform.workspace}-wc-master-sg"
  worker_security_group_name  = "${terraform.workspace}-wc-worker-sg"
  nfs_security_group_name     = "${terraform.workspace}-wc-nfs-sg"

  ssh_key_name                = "${terraform.workspace}-wc-ssh-key"
  ssh_pub_key_file            = var.ssh_pub_key_file_wc
  
  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
}
