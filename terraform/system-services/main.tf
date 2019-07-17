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

  master_name   = "${terraform.workspace}-ss-master"
  worker_1_name = "${terraform.workspace}-ss-worker1"
  worker_2_name = "${terraform.workspace}-ss-worker2"

  master_security_group_name = "${terraform.workspace}-ss-master-sg"
  worker_security_group_name = "${terraform.workspace}-ss-worker-sg"

  ssh_key_name     = "${terraform.workspace}-ss-ssh-key"
  ssh_pub_key_file = "${var.ssh_pub_key_file}"
}
