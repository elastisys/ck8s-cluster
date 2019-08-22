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
  version = "~> 0.11"
  key     = "${var.exoscale_api_key}"
  secret  = "${var.exoscale_secret_key}"

  timeout = 120 # default: waits 60 seconds in total for a resource
}

module "ss_cluster" {
  source                      = "./modules/kubernetes-cluster"

  master_name                 = "${terraform.workspace}-ss-master"
  worker_name                 = "${terraform.workspace}-ss-worker"
  worker_count                = "${var.ss_worker_count}"

  network_name                = "${terraform.workspace}-ss-network"
  nfs_name                    = "${terraform.workspace}-ss-nfs"
  dns_name                    = "${var.dns_prefix}-ss"

  master_security_group_name  = "${terraform.workspace}-ss-master-sg"
  worker_security_group_name  = "${terraform.workspace}-ss-worker-sg"
  nfs_security_group_name     = "${terraform.workspace}-ss-nfs-sg"

  ssh_key_name                = "${terraform.workspace}-ss-ssh-key"
  ssh_pub_key_file            = "${var.ssh_pub_key_file_ss}"
  
  public_ingress_cidr_whitelist = "${var.public_ingress_cidr_whitelist}"

}


module "c_cluster" {
  source                      = "./modules/kubernetes-cluster"

  master_name                 = "${terraform.workspace}-c-master"
  worker_name                 = "${terraform.workspace}-c-worker"
  worker_count                = "${var.c_worker_count}"

  network_name                = "${terraform.workspace}-c-network"
  nfs_name                    = "${terraform.workspace}-c-nfs"
  dns_name                    = "${var.dns_prefix}-c"

  master_security_group_name  = "${terraform.workspace}-c-master-sg"
  worker_security_group_name  = "${terraform.workspace}-c-worker-sg"
  nfs_security_group_name     = "${terraform.workspace}-c-nfs-sg"

  ssh_key_name                = "${terraform.workspace}-c-ssh-key"
  ssh_pub_key_file            = "${var.ssh_pub_key_file_c}"
  
  public_ingress_cidr_whitelist = "${var.public_ingress_cidr_whitelist}"
}
