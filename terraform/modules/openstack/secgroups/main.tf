resource "openstack_networking_secgroup_v2" "cluster" {
  name        = "${var.prefix}-cluster"
  description = "Elastisys Compliant Kubernetes cluster security group"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  for_each = toset(var.public_ingress_cidr_whitelist)

  # TODO: We should have a separate security group for ssh to keep things clean
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

# TODO: We should try to limit this better. Currently it is not possible to
# just allow traffic internally in the security group because of this:
# https://ask.openstack.org/en/question/122858/octavia-health-check-ip-and-security-group/
# TL;DR: Adding the security group to the LB only allows traffic from its VIP
# private IP, but requests are actually coming from another private IP.
# To work around this we allow traffic from the entire subnet.
resource "openstack_networking_secgroup_rule_v2" "internal_subnet" {
  # https://github.com/terraform-providers/terraform-provider-openstack/issues/879
  depends_on = [openstack_networking_secgroup_rule_v2.internal_any]

  security_group_id = openstack_networking_secgroup_v2.cluster.id

  direction        = "ingress"
  ethertype        = "IPv4"
  remote_ip_prefix = "172.16.0.0/24"
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

  for_each = toset(var.nodeport_whitelist)

  # https://github.com/terraform-providers/terraform-provider-openstack/issues/879
  depends_on = [openstack_networking_secgroup_rule_v2.https]

  security_group_id = openstack_networking_secgroup_v2.worker.id

  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 30000
  port_range_max   = 32767
  remote_ip_prefix = each.value
}
