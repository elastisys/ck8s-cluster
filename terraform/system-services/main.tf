terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "elastisys"

    workspaces {
      prefix = "a1-demo-system-services-"
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

  network_name = "${terraform.workspace}-ss-network"

  master_name = "${terraform.workspace}-ss-master"

  worker_name  = "${terraform.workspace}-ss-worker"
  worker_count = "${var.worker_count}"

  nfs_name = "${terraform.workspace}-ss-nfs"

  master_security_group_name = "${terraform.workspace}-ss-master-sg"
  worker_security_group_name = "${terraform.workspace}-ss-worker-sg"
  nfs_security_group_name    = "${terraform.workspace}-ss-nfs-sg"

  ssh_key_name     = "${terraform.workspace}-ss-ssh-key"
  ssh_pub_key_file = "${var.ssh_pub_key_file}"
}
