module "network" {
  source = "../../../modules/openstack/network"

  prefix = var.prefix

  external_network_id = var.external_network_id
}

module "secgroups" {
  source = "../../../modules/openstack/secgroups"

  prefix = var.prefix

  public_ingress_cidr_whitelist = var.public_ingress_cidr_whitelist
}

resource "openstack_compute_keypair_v2" "sshkey" {
  name       = "${var.prefix}_ssh_key"
  public_key = file(pathexpand(var.ssh_pub_key))
}

module "master" {
  source = "../../../modules/openstack/vm"

  prefix          = var.prefix
  names           = var.master_names
  name_flavor_map = var.master_name_flavor_map
  image_id        = var.cluster_image
  key_pair        = openstack_compute_keypair_v2.sshkey.id

  external_network_name = var.external_network_name

  network_id = module.network.network_id
  subnet_id  = module.network.subnet_id

  security_group_ids = [
    module.secgroups.cluster_secgroup,
    module.secgroups.master_secgroup,
  ]
}

module "worker" {
  source = "../../../modules/openstack/vm"

  prefix          = var.prefix
  names           = var.worker_names
  name_flavor_map = var.worker_name_flavor_map
  image_id        = var.cluster_image
  key_pair        = openstack_compute_keypair_v2.sshkey.id

  external_network_name = var.external_network_name

  network_id = module.network.network_id
  subnet_id  = module.network.subnet_id

  security_group_ids = [
    module.secgroups.cluster_secgroup,
    module.secgroups.worker_secgroup,
  ]
}

module "haproxy_lb" {
  source = "../../../modules/openstack/vm"

  prefix          = var.prefix
  names           = var.loadbalancer_names
  name_flavor_map = var.loadbalancer_name_flavor_map
  image_id        = var.loadbalancer_image
  key_pair        = openstack_compute_keypair_v2.sshkey.id

  external_network_name = var.external_network_name

  network_id = module.network.network_id
  subnet_id  = module.network.subnet_id

  security_group_ids = [
    module.secgroups.cluster_secgroup,
    module.secgroups.master_secgroup,
    module.secgroups.worker_secgroup,
  ]
}

module "dns" {
  source = "../../../modules/openstack/aws-dns"

  dns_list = var.dns_list

  aws_dns_zone_id  = var.aws_dns_zone_id
  aws_dns_role_arn = var.aws_dns_role_arn

  record_ips = module.haproxy_lb.floating_ips
}
