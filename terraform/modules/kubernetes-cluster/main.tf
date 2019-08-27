locals {
  internal_cidr_prefix  = "172.16.0.0/24"
  internal_network_size = 100

  # TODO: Remove when managed virtual router/DHCP is working properly.
  master_internal_cidr_host_num  = 1
  nfs_internal_host_num          = 2
  worker_internal_host_num_start = 3
  internal_cidr_prefix_length = element(
    split("/", local.internal_cidr_prefix),
    1
  )
  master_internal_ip_address = cidrhost(
    local.internal_cidr_prefix,
    local.master_internal_cidr_host_num
  )
  nfs_internal_ip_address = cidrhost(
    local.internal_cidr_prefix,
    local.nfs_internal_host_num
  )
}

resource "exoscale_network" "net" {
  zone             = "${var.zone}"
  name             = "${var.network_name}"
  network_offering = "PrivNet"

  start_ip = cidrhost(local.internal_cidr_prefix, 1)
  end_ip   = cidrhost(local.internal_cidr_prefix, local.internal_network_size)
  netmask  = cidrnetmask(local.internal_cidr_prefix)
}

resource "exoscale_compute" "master" {
  display_name    = "${var.master_name}"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "${var.zone}"
  security_groups = ["${exoscale_security_group.master_sg.name}"]

  user_data = templatefile(
    "${path.module}/templates/master-cloud-init.tmpl",
    {
      admission_control_config_b64 = filebase64("${path.module}/manifest/admission-control-config.yaml"),
      podnodeselector_config_b64   = filebase64("${path.module}/manifest/podnodeselector.yaml"),
      audit_policy_b64             = filebase64("${path.module}/manifest/audit-policy.yaml"),

      # TODO: Remove when managed virtual router/DHCP is working properly.
      address = "${local.master_internal_ip_address}/${local.internal_cidr_prefix_length}",
    }
  )
}

#resource "exoscale_nic" "master_internal" {
#  compute_id = "${exoscale_compute.master.id}"
#  network_id = "${exoscale_network.net.id}"
#
#  # TODO: Remove when managed virtual router/DHCP is working properly.
#  ip_address = "${local.master_internal_ip_address}"
#}

resource "exoscale_compute" "worker" {
  count = "${var.worker_count}"

  display_name    = "${var.worker_name}-${count.index}"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "${var.worker_size}"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "${var.zone}"
  security_groups = ["${exoscale_security_group.worker_sg.name}"]

  user_data = templatefile(
    "${path.module}/templates/worker-cloud-init.tmpl",
    {
      # TODO: Remove when managed virtual router/DHCP is working properly.
      address = "${cidrhost(local.internal_cidr_prefix, local.worker_internal_host_num_start + count.index)}/${local.internal_cidr_prefix_length}"
    }
  )
}

#resource "exoscale_nic" "worker_internal" {
#  count = "${var.worker_count}"
#
#  compute_id = "${element(exoscale_compute.worker.*.id, count.index)}"
#  network_id = "${exoscale_network.net.id}"
#
#  # TODO: Remove when managed virtual router/DHCP is working properly.
#  ip_address = cidrhost(
#    local.internal_cidr_prefix,
#    local.worker_internal_host_num_start + count.index
#  )
#}

resource "exoscale_compute" "nfs" {
  display_name    = "${var.nfs_name}"
  template        = "Linux Ubuntu 19.04 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "${var.zone}"
  security_groups = ["${exoscale_security_group.nfs_sg.name}"]

  user_data = templatefile(
    "${path.module}/templates/nfs-cloud-init.tmpl",
    {
      worker_ips = "${exoscale_compute.worker.*.ip_address}"
      # internal_cidr_prefix = "${local.internal_cidr_prefix}"

      # TODO: Remove when managed virtual router/DHCP is working properly.
      address = "${local.nfs_internal_ip_address}/${local.internal_cidr_prefix_length}",
    }
  )
}

#resource "exoscale_nic" "nfs_internal" {
#  compute_id = "${exoscale_compute.nfs.id}"
#  network_id = "${exoscale_network.net.id}"
#
#  # TODO: Remove when managed virtual router/DHCP is working properly.
#  ip_address = "${local.nfs_internal_ip_address}"
#}

resource "exoscale_security_group" "master_sg" {
  name        = "${var.master_security_group_name}"
  description = "Security group for Kubernetes masters"
}

resource "exoscale_security_group_rules" "master_sg_rules" {
  security_group_id = "${exoscale_security_group.master_sg.id}"

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = "${var.public_ingress_cidr_whitelist}"
    ports     = ["22"]
  }

  # Kubernetes API
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }

  # TODO: This should not be required when using private networks but some
  #       stuff are still using eth0 for some reason.
  ingress {
    protocol = "TCP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
      "${var.nfs_security_group_name}",
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
      "${var.nfs_security_group_name}",
    ]
  }
}

resource "exoscale_security_group" "worker_sg" {
  name        = "${var.worker_security_group_name}"
  description = "security group for kubernetes worker nodes"
}

resource "exoscale_security_group_rules" "worker_sg_rules" {
  security_group_id = "${exoscale_security_group.worker_sg.id}"

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = "${var.public_ingress_cidr_whitelist}"
    ports     = ["22"]
  }

  # HTTP(S)
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["80", "443"]
  }

  # TODO: This should not be required when using private networks but some
  #       stuff are still using eth0 for some reason.
  ingress {
    protocol = "TCP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
      "${var.nfs_security_group_name}",
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
      "${var.nfs_security_group_name}",
    ]
  }
}

resource "exoscale_security_group" "nfs_sg" {
  name        = "${var.nfs_security_group_name}"
  description = "Security group for NFS node"
}

resource "exoscale_security_group_rules" "nfs_sg_rules" {
  security_group_id = "${exoscale_security_group.nfs_sg.id}"

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = "${var.public_ingress_cidr_whitelist}"
    ports     = ["22"]
  }

  # TODO: This should not be required when using private networks but some
  #       stuff are still using eth0 for some reason.
  ingress {
    protocol = "TCP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
      "${var.nfs_security_group_name}",
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
      "${var.nfs_security_group_name}",
    ]
  }
}

#resource "exoscale_ipaddress" "eip" {
#  zone                     = "${var.zone}"
#  healthcheck_mode         = "http"
#  healthcheck_port         = 10254
#  healthcheck_path         = "/healthz"
#  healthcheck_interval     = 10
#  healthcheck_timeout      = 2
#  healthcheck_strikes_ok   = 2
#  healthcheck_strikes_fail = 3
#}
#
#resource "exoscale_secondary_ipaddress" "eip_worker_association" {
#  count = "${var.worker_count}"
#
#  compute_id = "${element(exoscale_compute.worker.*.id, count.index)}"
#  ip_address = "${exoscale_ipaddress.eip.ip_address}"
#}

resource "exoscale_ssh_keypair" "ssh_key" {
  name       = "${var.ssh_key_name}"
  public_key = file(pathexpand("${var.ssh_pub_key_file}"))
}
