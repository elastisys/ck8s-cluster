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

  workers_ip = [
    for k, v in exoscale_compute.worker : exoscale_compute.worker[k].ip_address
  ]
  set = setproduct(var.dns_list, local.workers_ip)
}

data "exoscale_compute_template" "ubuntu" {
  zone = var.zone
  name = "Linux Ubuntu 18.04 LTS 64-bit"
}

resource "exoscale_network" "net" {
  zone = var.zone
  name = "${var.prefix}-network"
  #network_offering = "PrivNet"

  start_ip = cidrhost(local.internal_cidr_prefix, 1)
  end_ip   = cidrhost(local.internal_cidr_prefix, local.internal_network_size)
  netmask  = cidrnetmask(local.internal_cidr_prefix)
}

data "exoscale_compute_template" "os_image" {
  zone   = var.zone
  name   = var.compute_instance_image
  # TODO: remove this when the image is publicly published
  filter = "mine"
}

resource "exoscale_compute" "master" {
  for_each = toset(var.master_names)

  display_name    = "${var.prefix}-${each.value}"
  template_id     = data.exoscale_compute_template.os_image.id
  size            = var.master_name_size_map[each.value]
  disk_size       = 50
  key_pair        = exoscale_ssh_keypair.ssh_key.name
  state           = "Running"
  zone            = var.zone
  security_groups = [exoscale_security_group.master_sg.name]

  user_data = templatefile(
    "${path.module}/templates/master-cloud-init.tmpl",
    {
      eip_ip_address               = exoscale_ipaddress.ingress_controller_lb.ip_address

      # TODO: Remove when managed virtual router/DHCP is working properly.
      # address = "${local.master_internal_ip_address}/${local.internal_cidr_prefix_length}",
    }
  )
}

#resource "exoscale_nic" "master_internal" {
#  compute_id = exoscale_compute.master.id
#  network_id = exoscale_network.net.id
#
#  # TODO: Remove when managed virtual router/DHCP is working properly.
#  ip_address = local.master_internal_ip_address
#}

resource "exoscale_compute" "worker" {
  for_each = toset(var.worker_names)

  display_name    = "${var.prefix}-${each.value}"
  template_id     = data.exoscale_compute_template.os_image.id
  size            = var.worker_name_size_map[each.value]
  disk_size       = 50
  key_pair        = exoscale_ssh_keypair.ssh_key.name
  state           = "Running"
  zone            = var.zone
  security_groups = [exoscale_security_group.worker_sg.name]

  user_data = templatefile(
    "${path.module}/templates/worker-cloud-init.tmpl",
    {
      # TODO: Remove when managed virtual router/DHCP is working properly.
      # address = "${cidrhost(local.internal_cidr_prefix, local.worker_internal_host_num_start + count.index)}/${local.internal_cidr_prefix_length
      eip_ip_address = exoscale_ipaddress.ingress_controller_lb.ip_address
    }
  )
}

#resource "exoscale_nic" "worker_internal" {
#  count = var.worker_count
#
#  compute_id = element(exoscale_compute.worker.*.id, count.index)
#  network_id = exoscale_network.net.id
#
#  # TODO: Remove when managed virtual router/DHCP is working properly.
#  ip_address = cidrhost(
#    local.internal_cidr_prefix,
#    local.worker_internal_host_num_start + count.index
#  )
#}

resource "exoscale_compute" "nfs" {
  display_name    = "${var.prefix}-nfs"
  template_id     = data.exoscale_compute_template.ubuntu.id
  size            = var.nfs_size
  disk_size       = 200
  key_pair        = exoscale_ssh_keypair.ssh_key.name
  state           = "Running"
  zone            = var.zone
  security_groups = [exoscale_security_group.nfs_sg.name]

  user_data = templatefile(
    "${path.module}/templates/nfs-cloud-init.tmpl",
    {
      #worker_ips = exoscale_compute.worker[*].ip_address
      worker_ips = local.workers_ip
      # internal_cidr_prefix = local.internal_cidr_prefix

      # TODO: Remove when managed virtual router/DHCP is working properly.
      # address = local.nfs_internal_ip_address}/${local.internal_cidr_prefix_length,
      eip_ip_address = exoscale_ipaddress.ingress_controller_lb.ip_address
    }
  )
}

#resource "exoscale_nic" "nfs_internal" {
#  compute_id = exoscale_compute.nfs.id
#  network_id = exoscale_network.net.id
#
#  # TODO: Remove when managed virtual router/DHCP is working properly.
#  ip_address = local.nfs_internal_ip_address
#}

resource "exoscale_security_group" "master_sg" {
  name        = "${var.prefix}-master-sg"
  description = "Security group for Kubernetes masters"
}

resource "exoscale_security_group_rules" "master_sg_rules" {
  security_group_id = exoscale_security_group.master_sg.id

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = var.public_ingress_cidr_whitelist
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
      exoscale_security_group.master_sg.name,
      exoscale_security_group.worker_sg.name,
      exoscale_security_group.nfs_sg.name,
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      exoscale_security_group.master_sg.name,
      exoscale_security_group.worker_sg.name,
      exoscale_security_group.nfs_sg.name,
    ]
  }
}

resource "exoscale_security_group" "worker_sg" {
  name        = "${var.prefix}-worker-sg"
  description = "security group for kubernetes worker nodes"
}

resource "exoscale_security_group_rules" "worker_sg_rules" {
  security_group_id = exoscale_security_group.worker_sg.id

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = var.public_ingress_cidr_whitelist
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
      exoscale_security_group.master_sg.name,
      exoscale_security_group.worker_sg.name,
      exoscale_security_group.nfs_sg.name,
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      exoscale_security_group.master_sg.name,
      exoscale_security_group.worker_sg.name,
      exoscale_security_group.nfs_sg.name,
    ]
  }
}

resource "exoscale_security_group" "nfs_sg" {
  name        = "${var.prefix}-nfs-sg"
  description = "Security group for NFS node"
}

resource "exoscale_security_group_rules" "nfs_sg_rules" {
  security_group_id = exoscale_security_group.nfs_sg.id

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = var.public_ingress_cidr_whitelist
    ports     = ["22"]
  }

  # TODO: This should not be required when using private networks but some
  #       stuff are still using eth0 for some reason.
  ingress {
    protocol = "TCP"
    ports    = ["0-65535"]
    user_security_group_list = [
      exoscale_security_group.master_sg.name,
      exoscale_security_group.worker_sg.name,
      exoscale_security_group.nfs_sg.name,
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      exoscale_security_group.master_sg.name,
      exoscale_security_group.worker_sg.name,
      exoscale_security_group.nfs_sg.name,
    ]
  }
}

resource "exoscale_ipaddress" "ingress_controller_lb" {
  zone                     = var.zone
  healthcheck_mode         = "http"
  healthcheck_port         = 80
  healthcheck_path         = "/healthz"
  healthcheck_interval     = 10
  healthcheck_timeout      = 2
  healthcheck_strikes_ok   = 2
  healthcheck_strikes_fail = 3
}

resource "exoscale_secondary_ipaddress" "ingress_controller_lb" {
  for_each = toset(var.worker_names)

  compute_id = exoscale_compute.worker[each.value].id
  ip_address = exoscale_ipaddress.ingress_controller_lb.ip_address
}

resource "exoscale_ssh_keypair" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = trimspace(file(pathexpand(var.ssh_pub_key_file)))
}

resource "exoscale_domain_record" "ingress" {
  for_each = toset(var.dns_list)

  domain      = var.dns_suffix
  name        = each.value
  record_type = "A"
  content     = exoscale_ipaddress.ingress_controller_lb.ip_address
}
