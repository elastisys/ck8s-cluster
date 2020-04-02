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


resource "openstack_compute_secgroup_v2" "cluster_sg" {
  name = "${var.prefix}-cluster-sg"

  description = "Elastisys Compliant Kubernetes cluster security group"


  # TODO: Ideally we would like to use separate rule resources to more easily
  #       update rules in-place instead of forcing re-creations. Unfortunately
  #       this seems to be causing issues right now. Needs to be investigated
  #       further.

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    self        = true
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    self        = true
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    self        = true
  }

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "194.132.164.168/32"
  }
}

# resource "openstack_networking_secgroup_rule_v2" "ssh" {
#   security_group_id = "${openstack_networking_secgroup_v2.cluster_sg.id}"

#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 22
#   port_range_max    = 22
#   remote_ip_prefix  = "0.0.0.0/0"
# }

# resource "openstack_networking_secgroup_rule_v2" "internal_icmp" {
#   security_group_id = "${openstack_networking_secgroup_v2.cluster_sg.id}"

#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "icmp"
#   port_range_min    = 0
#   port_range_max    = 0
#   remote_group_id   = "${openstack_networking_secgroup_v2.cluster_sg.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "internal_tcp" {
#   security_group_id = "${openstack_networking_secgroup_v2.cluster_sg.id}"

#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 1
#   port_range_max    = 65535
#   remote_group_id   = "${openstack_networking_secgroup_v2.cluster_sg.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "internal_udp" {
#   security_group_id = "${openstack_networking_secgroup_v2.cluster_sg.id}"

#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "udp"
#   port_range_min    = 1
#   port_range_max    = 65535
#   remote_group_id   = "${openstack_networking_secgroup_v2.cluster_sg.id}"
# }

resource "openstack_compute_secgroup_v2" "master_sg" {
  name = "${var.prefix}-master-sg"

  description = "Elastisys Compliant Kubernetes master security group"

  rule {
    from_port   = 6443
    to_port     = 6443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
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
    openstack_compute_secgroup_v2.cluster_sg.id,
    openstack_compute_secgroup_v2.master_sg.id,
  ]
}

resource "openstack_compute_secgroup_v2" "worker_sg" {
  name = "${var.prefix}-worker-sg"

  description = "Elastisys Compliant Kubernetes worker security group"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # We allow the default NodePort range
  # https://kubernetes.io/docs/concepts/loadbalancers-networking/loadbalancer/#nodeport
  rule {
    from_port   = 30000
    to_port     = 32767
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
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
    openstack_compute_secgroup_v2.cluster_sg.id,
    openstack_compute_secgroup_v2.worker_sg.id,
  ]
}

resource "openstack_blockstorage_volume_v2" "worker_volume" {
  # Cannot use simply use the default value '[""]' in the variable directly for some reason.
  for_each = var.worker_extra_volume == [] ? toset([""]) : toset(var.worker_extra_volume)
  name     = each.value
  size     = var.worker_extra_volume_size[each.value]
}

resource "openstack_compute_volume_attach_v2" "worker_va" {
  for_each    = var.worker_extra_volume == [] ? toset([""]) : toset(var.worker_extra_volume)
  instance_id = module.worker.instance_ids[each.value]
  volume_id   = openstack_blockstorage_volume_v2.worker_volume[each.value].id
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