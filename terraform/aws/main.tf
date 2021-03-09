provider "aws" {
  version    = "~> 2.50"
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "kubernetes" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix

  aws_region = var.region

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist

  ssh_pub_key = var.ssh_pub_key

  machines   = var.machines
  extra_tags = var.extra_tags
}

data "template_file" "inventory" {
  template = file("${path.root}/templates/inventory.tpl")

  vars = {
    connection_strings_master = join("\n", formatlist("%s ansible_user=ubuntu ansible_host=%s ip=%s etcd_member_name=etcd%d",
      keys(module.kubernetes.master_ips),
      values(module.kubernetes.master_ips).*.public_ip,
      values(module.kubernetes.master_ips).*.private_ip,
    range(1, length(module.kubernetes.master_ips) + 1)))
    connection_strings_worker = join("\n", formatlist("%s ansible_user=ubuntu ansible_host=%s ip=%s",
      keys(module.kubernetes.worker_ips),
      values(module.kubernetes.worker_ips).*.public_ip,
    values(module.kubernetes.worker_ips).*.private_ip))

    list_master       = join("\n", keys(module.kubernetes.master_ips))
    list_worker       = join("\n", keys(module.kubernetes.worker_ips))
    api_lb_ip_address = module.kubernetes.master_internal_loadbalancer_fqdn
  }
}

resource "null_resource" "inventories" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.inventory.rendered}' > inventory.ini"
  }

  triggers = {
    template = data.template_file.inventory.rendered
  }
}