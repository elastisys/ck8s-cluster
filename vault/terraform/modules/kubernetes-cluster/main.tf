resource "exoscale_compute" "master" {
  count = "${var.master_count}"

  display_name    = "${var.master_name}-${count.index}"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "${var.master_size}"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "${var.zone}"
  security_groups = ["${exoscale_security_group.master_sg.name}"]
}


resource "exoscale_compute" "nfs" {
  display_name    = "${var.nfs_name}"
  template        = "Linux Ubuntu 19.04 64-bit"
  size            = "${var.nfs_size}"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "${var.zone}"
  security_groups = ["${exoscale_security_group.nfs_sg.name}"]

  user_data = templatefile(
    "${path.module}/templates/nfs-cloud-init.tmpl",
    {
      worker_ips = "${exoscale_compute.master.*.ip_address}"
    }
  )
}

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

  # HTTP(S)
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["80", "443"]
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
      "${exoscale_security_group.master_sg.name}",
      "${exoscale_security_group.nfs_sg.name}",
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${exoscale_security_group.master_sg.name}",
      "${exoscale_security_group.nfs_sg.name}",
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

  ingress {
    protocol = "TCP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${exoscale_security_group.master_sg.name}",
      "${exoscale_security_group.nfs_sg.name}",
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${exoscale_security_group.master_sg.name}",
      # "${exoscale_security_group.worker_sg.name}",
      "${exoscale_security_group.nfs_sg.name}",
    ]
  }
}

resource "exoscale_ssh_keypair" "ssh_key" {
  name       = "${var.ssh_key_name}"
  public_key = file(pathexpand("${var.ssh_pub_key_file}"))
}
