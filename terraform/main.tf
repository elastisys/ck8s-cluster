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

module "system_services_cluster" {
  source                      = "./modules/kubernetes-cluster"

  master_name                 = "${terraform.workspace}-system-services-master"
  worker_name                 = "${terraform.workspace}-system-services-worker"
  worker_count                = "${var.system_services_worker_count}"
  worker_size                 = "${var.system_services_worker_size}"

  network_name                = "${terraform.workspace}-system-services-network"
  nfs_name                    = "${terraform.workspace}-system-services-nfs"
  dns_name                    = "${var.dns_prefix}-system-services"

  master_security_group_name  = "${terraform.workspace}-system-services-master-sg"
  worker_security_group_name  = "${terraform.workspace}-system-services-worker-sg"
  nfs_security_group_name     = "${terraform.workspace}-system-services-nfs-sg"

  ssh_key_name                = "${terraform.workspace}-system-services-ssh-key"
  ssh_pub_key_file            = "${var.ssh_pub_key_file_system_services}"
  
  public_ingress_cidr_whitelist = "${var.public_ingress_cidr_whitelist}"

}


module "customer_cluster" {
  source                      = "./modules/kubernetes-cluster"

  master_name                 = "${terraform.workspace}-customer-master"
  worker_name                 = "${terraform.workspace}-customer-worker"
  worker_count                = "${var.customer_worker_count}"
  worker_size                 = "${var.customer_worker_size}"

  network_name                = "${terraform.workspace}-customer-network"
  nfs_name                    = "${terraform.workspace}-customer-nfs"
  dns_name                    = "${var.dns_prefix}-customer"

  master_security_group_name  = "${terraform.workspace}-customer-master-sg"
  worker_security_group_name  = "${terraform.workspace}-customer-worker-sg"
  nfs_security_group_name     = "${terraform.workspace}-customer-nfs-sg"

  ssh_key_name                = "${terraform.workspace}-customer-ssh-key"
  ssh_pub_key_file            = "${var.ssh_pub_key_file_customer}"
  
  public_ingress_cidr_whitelist = "${var.public_ingress_cidr_whitelist}"
}
