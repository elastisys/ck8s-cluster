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
    cidr        = "0.0.0.0/0"
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

  instance_name  = "${var.prefix}-master"
  instance_count = var.master_count

  image_id  = var.image_id
  flavor_id = var.master_flavor_id
  key_pair  = var.key_pair

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
  # https://kubernetes.io/docs/concepts/services-networking/service/#nodeport
  rule {
    from_port   = 30000
    to_port     = 32767
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

module "worker" {
  source = "../vm"

  instance_name  = "${var.prefix}-worker"
  instance_count = var.worker_count

  image_id  = var.image_id
  flavor_id = var.worker_flavor_id
  key_pair  = var.key_pair

  network_id = openstack_networking_network_v2.network.id
  subnet_id  = openstack_networking_subnet_v2.subnet.id
  security_group_ids = [
    openstack_compute_secgroup_v2.cluster_sg.id,
    openstack_compute_secgroup_v2.worker_sg.id,
  ]
}

module "nfs" {
  source = "../vm"

  instance_name = "${var.prefix}-nfs"

  image_id  = var.image_id
  flavor_id = var.nfs_flavor_id
  key_pair  = var.key_pair

  network_id = openstack_networking_network_v2.network.id
  subnet_id  = openstack_networking_subnet_v2.subnet.id
  security_group_ids = [
    openstack_compute_secgroup_v2.cluster_sg.id,
  ]
}

resource "openstack_blockstorage_volume_v2" "nfs_volume" {
  name = "${var.prefix}-nfs-volume"
  size = var.nfs_storage_size
}

resource "openstack_compute_volume_attach_v2" "nfs_va" {
  instance_id = module.nfs.instance_ids[0]
  volume_id   = openstack_blockstorage_volume_v2.nfs_volume.id
}
