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

  master_name   = "${terraform.workspace}-c-master"
  worker_1_name = "${terraform.workspace}-c-worker1"
  worker_2_name = "${terraform.workspace}-c-worker2"

  master_security_group_name = "${terraform.workspace}-c-master-sg"
  worker_security_group_name = "${terraform.workspace}-c-worker-sg"

  ssh_key_name     = "${terraform.workspace}-c-ssh-key"
  ssh_pub_key_file = "${var.ssh_pub_key_file}"
}
