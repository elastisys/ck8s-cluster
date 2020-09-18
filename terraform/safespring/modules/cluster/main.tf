locals {
  subnet_cidr = "172.16.0.0/24"
}

module "network" {
  source = "../../../modules/openstack/network"

  prefix = var.prefix

  external_network_id = var.external_network_id

  subnet_cidr = local.subnet_cidr
}

module "secgroups" {
  source = "../../../modules/openstack/secgroups"

  prefix = var.prefix

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
  api_server_whitelist          = var.api_server_whitelist
  nodeport_whitelist            = var.nodeport_whitelist
}

resource "openstack_compute_keypair_v2" "sshkey" {
  name       = "${var.prefix}_ssh_key"
  public_key = file(pathexpand(var.ssh_pub_key))
}

resource "openstack_compute_servergroup_v2" "master_anti_affinity" {
  # You are not allowed to create a servergroup with an empty policy
  count = var.master_anti_affinity_policy != "" ? 1 : 0

  name     = "${var.prefix}-master-anti-affinity"
  policies = [var.master_anti_affinity_policy]
}

module "master" {
  source = "../../../modules/openstack/vm"

  prefix = var.prefix
  machines = {
    for name, machine in var.machines : name => machine
    if machine.node_type == "master"
  }
  key_pair = openstack_compute_keypair_v2.sshkey.id

  external_network_name = var.external_network_name

  network_id = module.network.network_id
  subnet_id  = module.network.subnet_id

  security_group_ids = [
    module.secgroups.cluster_secgroup,
    module.secgroups.master_secgroup,
  ]

  server_group_id = var.master_anti_affinity_policy != "" ? openstack_compute_servergroup_v2.master_anti_affinity[0].id : ""
}

resource "openstack_compute_servergroup_v2" "worker_anti_affinity" {
  # You are not allowed to create a servergroup with an empty policy
  count = var.worker_anti_affinity_policy != "" ? 1 : 0

  name     = "${var.prefix}-worker-anti-affinity"
  policies = [var.worker_anti_affinity_policy]
}

module "worker" {
  source = "../../../modules/openstack/vm"

  prefix = var.prefix
  machines = {
    for name, machine in var.machines : name => machine
    if machine.node_type == "worker"
  }
  key_pair = openstack_compute_keypair_v2.sshkey.id

  external_network_name = var.external_network_name

  network_id = module.network.network_id
  subnet_id  = module.network.subnet_id

  security_group_ids = [
    module.secgroups.cluster_secgroup,
    module.secgroups.worker_secgroup,
  ]

  server_group_id = var.worker_anti_affinity_policy != "" ? openstack_compute_servergroup_v2.worker_anti_affinity[0].id : ""
}

module "haproxy_lb" {
  source = "../../../modules/openstack/vm"

  prefix = var.prefix
  machines = {
    for name, machine in var.machines : name => machine
    if machine.node_type == "loadbalancer"
  }
  key_pair = openstack_compute_keypair_v2.sshkey.id

  external_network_name = var.external_network_name

  network_id = module.network.network_id
  subnet_id  = module.network.subnet_id

  security_group_ids = [
    module.secgroups.cluster_secgroup,
    module.secgroups.master_secgroup,
    module.secgroups.worker_secgroup,
  ]

  server_group_id = ""
}

module "dns" {
  source = "../../../modules/openstack/aws-dns"

  dns_list   = var.dns_list
  dns_prefix = var.dns_prefix

  aws_dns_zone_id  = var.aws_dns_zone_id
  aws_dns_role_arn = var.aws_dns_role_arn

  record_ips = module.haproxy_lb.floating_ips
}
