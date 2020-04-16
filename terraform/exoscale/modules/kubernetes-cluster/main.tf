data "exoscale_compute_template" "ubuntu" {
  zone = var.zone
  name = "Linux Ubuntu 18.04 LTS 64-bit"
}

data "exoscale_compute_template" "os_image" {
  zone = var.zone
  name = var.compute_instance_image
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
}

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
      eip_ip_address            = exoscale_ipaddress.ingress_controller_lb.ip_address
      es_local_storage_capacity = var.es_local_storage_capacity_map[each.value]
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
      worker_ips = [
        for k, v in exoscale_compute.worker :
        exoscale_compute.worker[k].ip_address
      ]

      eip_ip_address = exoscale_ipaddress.ingress_controller_lb.ip_address
    }
  )
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
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }

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
  ingress {
    protocol = "IPIP"
    ports    = ["0"]
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
  ingress {
    protocol = "IPIP"
    ports    = ["0"]
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
  for_each = toset(var.master_names)

  compute_id = exoscale_compute.master[each.value].id
  ip_address = exoscale_ipaddress.control_plane_lb.ip_address
}

resource "exoscale_ssh_keypair" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = trimspace(file(pathexpand(var.ssh_pub_key)))
}

resource "exoscale_domain_record" "ingress" {
  for_each = toset(var.dns_list)

  domain      = var.dns_suffix
  name        = each.value
  record_type = "A"
  content     = exoscale_ipaddress.ingress_controller_lb.ip_address
}
