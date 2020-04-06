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

  prefix            = var.prefix
  names             = var.master_names
  name_flavor_map   = var.master_name_flavor_map
  image_id          = var.image_id
  key_pair          = var.key_pair
  public_v4_network = var.public_v4_network

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

  prefix            = var.prefix
  names             = var.worker_names
  name_flavor_map   = var.worker_name_flavor_map
  image_id          = var.image_id
  key_pair          = var.key_pair
  public_v4_network = var.public_v4_network

  network_id = openstack_networking_network_v2.network.id
  subnet_id  = openstack_networking_subnet_v2.subnet.id

  security_group_ids = [
    openstack_networking_secgroup_v2.cluster.id,
    openstack_networking_secgroup_v2.worker.id,
  ]
}

#
# Loadbalancer
#

resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
  name          = "${var.prefix}-k8s-loadbalancer-1"
  vip_subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_lb_listener_v2" "loadbalancer-80" {
  name            = "${var.prefix}-loadbalancer-80"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
  default_pool_id = openstack_lb_pool_v2.loadbalancer-http.id
}

resource "openstack_lb_listener_v2" "loadbalancer-443" {
  name            = "${var.prefix}-loadbalancer-443"
  protocol        = "HTTPS"
  protocol_port   = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
  default_pool_id = openstack_lb_pool_v2.loadbalancer-https.id
}

resource "openstack_lb_pool_v2" "loadbalancer-http" {
  name            = "${var.prefix}-loadbalancer-80"
  lb_method       = "ROUND_ROBIN"
  protocol        = "HTTP"
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
}

resource "openstack_lb_pool_v2" "loadbalancer-https" {
  name            = "${var.prefix}-loadbalancer-443"
  lb_method       = "ROUND_ROBIN"
  protocol        = "HTTPS"
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
}

resource "openstack_lb_member_v2" "loadbalancer-80" {
  for_each = module.worker.instance_ips

  address       = each.value.private_ip
  pool_id       = openstack_lb_pool_v2.loadbalancer-http.id
  protocol_port = 80
  subnet_id     = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_lb_member_v2" "loadbalancer-443" {
  for_each = module.worker.instance_ips

  address       = each.value.private_ip
  pool_id       = openstack_lb_pool_v2.loadbalancer-https.id
  protocol_port = 443
  subnet_id     = openstack_networking_subnet_v2.subnet.id
}

data "openstack_networking_network_v2" "ext-net" {
  name = "ext-net"
}

resource "openstack_networking_floatingip_v2" "loadbalancer-lb-fip" {
  pool = data.openstack_networking_network_v2.ext-net.name
}

resource "openstack_networking_floatingip_associate_v2" "loadbalancer-lb-fip-assoc" {
  floating_ip = openstack_networking_floatingip_v2.loadbalancer-lb-fip.address
  port_id     = openstack_lb_loadbalancer_v2.loadbalancer.vip_port_id
  depends_on = [
    openstack_lb_loadbalancer_v2.loadbalancer,
    openstack_lb_listener_v2.loadbalancer-80,
    openstack_lb_listener_v2.loadbalancer-443
  ]
}

# Health Monitor

# resource "openstack_lb_monitor_v2" "loadbalancer-80" {
#   name = "${var.prefix}-loadbalancer-80"
#   pool_id = openstack_lb_pool_v2.loadbalancer-http.id
#   type = "PING"
#   delay = 20
#   timeout = 10
#   max_retries = 5
# }

# resource "openstack_lb_monitor_v2" "loadbalancer-443" {
#   name = "${var.prefix}-loadbalancer-443"
#   pool_id = openstack_lb_pool_v2.loadbalancer-https.id
#   type = "PING"
#   delay = 20
#   timeout = 10
#   max_retries = 5
# }