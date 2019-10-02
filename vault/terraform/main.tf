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

module "vault_cluster" {
  source                      = "./modules/kubernetes-cluster"

  master_name                 = "${terraform.workspace}-vault-master"
  master_count                = "${var.vault_master_count}"
  master_size                 = "${var.vault_master_size}"

  nfs_name                    = "${terraform.workspace}-vault-nfs"
  nfs_size                    = "${var.vault_nfs_size}"

  network_name                = "${terraform.workspace}-vault-network"
  dns_name                    = "${var.dns_prefix}-vault"

  master_security_group_name  = "${terraform.workspace}-vault-master-sg"
  nfs_security_group_name     = "${terraform.workspace}-vault-nfs-sg"

  ssh_key_name                = "${terraform.workspace}-vault-ssh-key"
  ssh_pub_key_file            = "${var.ssh_pub_key_file_vault}"
  
  public_ingress_cidr_whitelist = "${var.public_ingress_cidr_whitelist}"
}
