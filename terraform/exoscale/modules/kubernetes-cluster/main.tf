data "exoscale_compute_template" "ubuntu" {
  zone = var.zone
  name = "Linux Ubuntu 18.04 LTS 64-bit"
}

data "exoscale_compute_template" "os_image" {
  for_each = var.machines

  zone = var.zone
  name = each.value.image.name
  # TODO: remove this when the image is publicly published
  filter = "mine"
}

data "exoscale_compute" "master_nodes" {
  for_each = exoscale_compute.master

  id = each.value.id

  # Since private IP address is not assigned until the nics are created we need this
  depends_on = [exoscale_nic.master_private_network_nic]
}

data "exoscale_compute" "worker_nodes" {
  for_each = exoscale_compute.worker

  id = each.value.id

  # Since private IP address is not assigned until the nics are created we need this
  depends_on = [exoscale_nic.worker_private_network_nic]
}

data "exoscale_compute" "nfs_node" {
  id = exoscale_compute.nfs.id

  # Since private IP address is not assigned until the nics are created we need this
  depends_on = [exoscale_nic.nfs_private_network_nic]
}

resource "exoscale_network" "private_network" {
  zone = var.zone
  name = "${var.prefix}-network"

  start_ip = cidrhost(var.private_network_cidr, 1)
  # cidr -1 = Broadcast address
  # cidr -2 = DHCP server address (exoscale specific)
  end_ip  = cidrhost(var.private_network_cidr, -3)
  netmask = cidrnetmask(var.private_network_cidr)
}

# TODO: We should probably be able to combine all compute resources into one
#       but it will be breaking existing resources, so let's keep them as is
#       for now.

resource "exoscale_compute" "master" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "master"
  }

  display_name    = "${var.prefix}-${each.key}"
  template_id     = data.exoscale_compute_template.os_image[each.key].id
  size            = each.value.size
  disk_size       = 50
  key_pair        = exoscale_ssh_keypair.ssh_key.name
  state           = "Running"
  zone            = var.zone
  security_groups = [exoscale_security_group.master_sg.name]

  user_data = file("${path.module}/templates/master-cloud-init.yaml")
}

resource "exoscale_compute" "worker" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "worker"
  }

  display_name    = "${var.prefix}-${each.key}"
  template_id     = data.exoscale_compute_template.os_image[each.key].id
  size            = each.value.size
  disk_size       = 50
  key_pair        = exoscale_ssh_keypair.ssh_key.name
  state           = "Running"
  zone            = var.zone
  security_groups = [exoscale_security_group.worker_sg.name]

  user_data = templatefile(
    "${path.module}/templates/worker-cloud-init.tmpl",
    {
      eip_ip_address            = exoscale_ipaddress.ingress_controller_lb.ip_address
      es_local_storage_capacity = each.value.provider_settings == null ? 0 : each.value.provider_settings.es_local_storage_capacity
    }
  )
}

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
      private_network_cidr = var.private_network_cidr
    }
  )
}

resource "exoscale_nic" "master_private_network_nic" {
  for_each = exoscale_compute.master

  compute_id = each.value.id
  network_id = exoscale_network.private_network.id
}

resource "exoscale_nic" "worker_private_network_nic" {
  for_each = exoscale_compute.worker

  compute_id = each.value.id
  network_id = exoscale_network.private_network.id
}

resource "exoscale_nic" "nfs_private_network_nic" {
  compute_id = exoscale_compute.nfs.id
  network_id = exoscale_network.private_network.id
}

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
    cidr_list = var.api_server_whitelist
    ports     = ["6443"]
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

  # Kubernetes Nodeport
  ingress {
    protocol  = "TCP"
    cidr_list = var.nodeport_whitelist
    ports     = ["30000-32767"]
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
  for_each = exoscale_compute.worker

  compute_id = each.value.id
  ip_address = exoscale_ipaddress.ingress_controller_lb.ip_address
}

resource "exoscale_ipaddress" "control_plane_lb" {
  zone                     = var.zone
  healthcheck_mode         = "tcp"
  healthcheck_port         = 6443
  healthcheck_interval     = 10
  healthcheck_timeout      = 2
  healthcheck_strikes_ok   = 2
  healthcheck_strikes_fail = 3
}

resource "exoscale_secondary_ipaddress" "control_plane_lb" {
  for_each = exoscale_compute.master

  compute_id = each.value.id
  ip_address = exoscale_ipaddress.control_plane_lb.ip_address
}

resource "exoscale_ssh_keypair" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = trimspace(file(pathexpand(var.ssh_pub_key)))
}

resource "exoscale_domain_record" "ingress" {
  for_each = toset(var.dns_list)

  domain      = var.dns_suffix
  name        = "${each.value}.${var.dns_prefix}"
  record_type = "A"
  content     = exoscale_ipaddress.ingress_controller_lb.ip_address
}
