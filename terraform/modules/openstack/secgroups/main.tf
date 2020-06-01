resource "openstack_networking_secgroup_v2" "cluster" {
  name        = "${var.prefix}-cluster"
  description = "Elastisys Compliant Kubernetes cluster security group"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  for_each = toset(var.public_ingress_cidr_whitelist)

  security_group_id = openstack_networking_secgroup_v2.cluster.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
  remote_ip_prefix = each.value
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

resource "openstack_networking_secgroup_rule_v2" "kubernetes_api" {
  for_each          = toset(var.api_server_whitelist)
  security_group_id = openstack_networking_secgroup_v2.master.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 6443
  port_range_max   = 6443
  remote_ip_prefix = each.value
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
