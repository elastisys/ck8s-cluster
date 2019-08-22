terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "elastisys"

    workspaces {
      prefix = "a1-demo-customer-"
    }
  }
}

provider "exoscale" {
  version = "~> 0.11"
  key     = "${var.exoscale_api_key}"
  secret  = "${var.exoscale_secret_key}"

  timeout = 120 # default: waits 60 seconds in total for a resource
}

module "kubernetes_cluster" {
  source = "../modules/kubernetes-cluster"

  network_name = "${terraform.workspace}-c-network"

  master_name = "${terraform.workspace}-c-master"

  worker_name  = "${terraform.workspace}-c-worker"
  worker_count = "${var.worker_count}"

  nfs_name = "${terraform.workspace}-c-nfs"

  master_security_group_name = "${terraform.workspace}-c-master-sg"
  worker_security_group_name = "${terraform.workspace}-c-worker-sg"
  nfs_security_group_name    = "${terraform.workspace}-c-nfs-sg"

  ssh_key_name     = "${terraform.workspace}-c-ssh-key"
  ssh_pub_key_file = "${var.ssh_pub_key_file_c}"
  public_ingress_cidr_whitelist = "${var.public_ingress_cidr_whitelist}"

  dns_name = "${var.dns_prefix}-c"
}
