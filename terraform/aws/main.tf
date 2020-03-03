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
  dns_records = module.service_cluster.worker_ips.*.public_ip
}

module "workload_dns" {
  source = "../aws-dns"

  credentials_file_path = var.dns_credentials_file_path

  dns_list = [
    "*.${var.dns_prefix}",
    "prometheus.ops.${var.dns_prefix}"
  ]
  dns_records = module.workload_cluster.worker_ips.*.public_ip
}

data "template_file" "ansible_inventory" {
  template = file("${path.module}/templates/inventory.tmpl")
  vars  = {
    master_hosts = <<EOT
%{ for index,master in module.service_cluster.master_ips ~}
${var.prefix_sc}-master-${index} ansible_host=${master.public_ip} private_ip=${master.private_ip} ansible_ssh_private_key_file='${var.ansible_ssh_key_sc}'
%{ endfor ~}
%{ for index,master in module.workload_cluster.master_ips ~}
${var.prefix_wc}-master-${index} ansible_host=${master.public_ip} private_ip=${master.private_ip} ansible_ssh_private_key_file='${var.ansible_ssh_key_wc}'
%{ endfor ~}
EOT
    masters = <<EOT
%{ for index,master in module.service_cluster.master_ips ~}
${var.prefix_sc}-master-${index}
%{ endfor ~}
%{ for index,master in module.workload_cluster.master_ips ~}
${var.prefix_wc}-master-${index}
%{ endfor ~}
EOT
    worker_hosts = <<EOT
%{ for index,worker in module.service_cluster.worker_ips ~}
${var.prefix_sc}-worker-${index} ansible_host=${worker.public_ip} private_ip=${worker.private_ip} ansible_ssh_private_key_file='${var.ansible_ssh_key_sc}'
%{ endfor ~}
%{ for index,worker in module.workload_cluster.worker_ips ~}
${var.prefix_wc}-worker-${index} ansible_host=${worker.public_ip} private_ip=${worker.private_ip} ansible_ssh_private_key_file='${var.ansible_ssh_key_wc}'
%{ endfor ~}
EOT
    workers = <<EOT
%{ for index,worker in module.service_cluster.worker_ips ~}
${var.prefix_sc}-worker-${index}
%{ endfor ~}
%{ for index,worker in module.workload_cluster.worker_ips ~}
${var.prefix_wc}-worker-${index}
%{ endfor ~}
EOT
  }
}
