data "openstack_images_image_v2" "lb_image" {
  name        = "ubuntu-18.04-server-cloudimg-amd64-20190212.1"
  most_recent = true
}

resource "openstack_networking_network_v2" "network" {
  name           = "${var.prefix}-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name = "${var.prefix}-subnet"

  network_id = openstack_networking_network_v2.network.id

  cidr       = "172.16.0.0/24"
  ip_version = 4
  dns_nameservers = [
    "8.8.8.8",
    "8.8.4.4"
  ]
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.prefix}_router"
  external_network_id = var.public_v4_network
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_networking_secgroup_v2" "cluster" {
  name        = "${var.prefix}-cluster"
  description = "Elastisys Compliant Kubernetes cluster security group"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  security_group_id = openstack_networking_secgroup_v2.cluster.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
  remote_ip_prefix = var.public_ingress_cidr_whitelist
}

# TODO: Currently allows all protocols for internal traffic to allow IP-in-IP
#       since it's not currently supported as a protocol in the OpenStack
#       Terraform provider. Might want to configure specific protocols in the
#       future.
resource "openstack_networking_secgroup_rule_v2" "internal_any" {
  # https://github.com/terraform-providers/terraform-provider-openstack/issues/879
  depends_on = [openstack_networking_secgroup_rule_v2.ssh]

  security_group_id = openstack_networking_secgroup_v2.cluster.id

  direction       = "ingress"
  ethertype       = "IPv4"
  remote_group_id = openstack_networking_secgroup_v2.cluster.id
}

resource "openstack_networking_secgroup_v2" "master" {
  name        = "${var.prefix}-master"
  description = "Elastisys Compliant Kubernetes master security group"
}

# TODO: Whitelist.
resource "openstack_networking_secgroup_rule_v2" "kubernetes_api" {
  security_group_id = openstack_networking_secgroup_v2.master.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 6443
  port_range_max   = 6443
  remote_ip_prefix = "0.0.0.0/0"
}

module "master" {
  source = "../vm"

  prefix          = var.prefix
  names           = var.master_names
  name_flavor_map = var.master_name_flavor_map
  image_id        = var.image_id
  key_pair        = var.key_pair

  network_id = openstack_networking_network_v2.network.id
  subnet_id  = openstack_networking_subnet_v2.subnet.id

  security_group_ids = [
    openstack_networking_secgroup_v2.cluster.id,
    openstack_networking_secgroup_v2.master.id,
  ]
}

resource "openstack_networking_secgroup_v2" "worker" {
  name        = "${var.prefix}-worker"
  description = "Elastisys Compliant Kubernetes worker security group"
}

# TODO: Whitelist
resource "openstack_networking_secgroup_rule_v2" "http" {
  security_group_id = openstack_networking_secgroup_v2.worker.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 80
  port_range_max   = 80
  remote_ip_prefix = "0.0.0.0/0"
}

# TODO: Whitelist
resource "openstack_networking_secgroup_rule_v2" "https" {
  # https://github.com/terraform-providers/terraform-provider-openstack/issues/879
  depends_on = [openstack_networking_secgroup_rule_v2.http]

  security_group_id = openstack_networking_secgroup_v2.worker.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 443
  port_range_max   = 443
  remote_ip_prefix = "0.0.0.0/0"
}

# TODO: Is this really necessary?
# We allow the default NodePort range
# https://kubernetes.io/docs/concepts/services-networking/service/#nodeport
resource "openstack_networking_secgroup_rule_v2" "nodeports" {
  # https://github.com/terraform-providers/terraform-provider-openstack/issues/879
  depends_on = [openstack_networking_secgroup_rule_v2.https]

  security_group_id = openstack_networking_secgroup_v2.worker.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 30000
  port_range_max   = 32767
  remote_ip_prefix = "0.0.0.0/0"
}

module "worker" {
  source = "../vm"

  prefix          = var.prefix
  names           = var.worker_names
  name_flavor_map = var.worker_name_flavor_map
  image_id        = var.image_id
  key_pair        = var.key_pair

  network_id = openstack_networking_network_v2.network.id
  subnet_id  = openstack_networking_subnet_v2.subnet.id

  security_group_ids = [
    openstack_networking_secgroup_v2.cluster.id,
    openstack_networking_secgroup_v2.worker.id,
  ]
}

module "loadbalancer" {
  source = "../vm"

  prefix          = var.prefix
  names           = var.loadbalancer_names
  name_flavor_map = var.loadbalancer_name_flavor_map
  image_id        = data.openstack_images_image_v2.lb_image.id
  key_pair        = var.key_pair

  network_id = openstack_networking_network_v2.network.id
  subnet_id  = openstack_networking_subnet_v2.subnet.id

  security_group_ids = [
    openstack_networking_secgroup_v2.cluster.id,
    openstack_networking_secgroup_v2.worker.id,
  ]
}
