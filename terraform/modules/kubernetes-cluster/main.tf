resource "exoscale_compute" "master" {
  display_name    = "${var.master_name}"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.master-sg.name}"]

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/kubernetes/conf",
      "sudo chown rancher:rancher /etc/kubernetes/conf"
    ]

    connection {
      type = "ssh"
      user = "rancher"
      host = "${self.ip_address}"
    }
  }

  provisioner "file" {
    source      = "${path.module}/../../../manifests/pod-node-restriction/admission-control-config.yaml"
    destination = "/etc/kubernetes/conf/admission-control-config.yaml"

    connection {
      type = "ssh"
      user = "rancher"
      host = "${self.ip_address}"
    }
  }

  provisioner "file" {
    source      = "${path.module}/../../../manifests/pod-node-restriction/podnodeselector.yaml"
    destination = "/etc/kubernetes/conf/podnodeselector.yaml"

    connection {
      type = "ssh"
      user = "rancher"
      host = "${self.ip_address}"
    }
  }

  provisioner "file" {
    source      = "${path.module}/../../../manifests/audit-policy.yaml"
    destination = "/etc/kubernetes/conf/audit-policy.yaml"

    connection {
      type = "ssh"
      user = "rancher"
      host = "${self.ip_address}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown -R root:root /etc/kubernetes/conf"
    ]

    connection {
      type = "ssh"
      user = "rancher"
      host = "${self.ip_address}"
    }
  }
}

resource "exoscale_compute" "worker1" {
  display_name    = "${var.worker_1_name}"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.worker-sg.name}"]
  user_data       = "${file("${path.module}/../../../falco/cloud.cfg")}"
}

resource "exoscale_compute" "worker2" {
  display_name    = "${var.worker_2_name}"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.worker-sg.name}"]
  user_data       = "${file("${path.module}/../../../falco/cloud.cfg")}"
}

resource "exoscale_compute" "nfs" {
  display_name    = "${terraform.workspace}-nfs-storage"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.worker-sg.name}"]
  user_data       = <<EOF
#cloud-config
runcmd:
  - sudo apt-get install nfs-kernel-server -y
  - sudo mkdir -p /nfs && sudo chown nobody:nogroup /nfs
  - echo "/nfs ${exoscale_compute.worker1.ip_address}(rw,sync,no_subtree_check,no_root_squash) ${exoscale_compute.master.ip_address}(rw,sync,no_subtree_check,no_root_squash) ${exoscale_compute.worker2.ip_address}(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
  - sudo exportfs -rav
  - sudo ufw allow 2049
EOF

}

resource "exoscale_security_group" "master-sg" {
  name        = "${var.master_security_group_name}"
  description = "Security group for Kubernetes masters"
}

resource "exoscale_security_group_rules" "master-rules" {
  security_group_id = "${exoscale_security_group.master-sg.id}"

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = "${var.public_ingress_cidr_whitelist}"
    ports     = ["22"]
  }

  # Allow all internal communication
  ingress {
    protocol = "TCP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
    ]
  }

  # Master specific ports
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }
}

resource "exoscale_security_group" "worker-sg" {
  name        = "${var.worker_security_group_name}"
  description = "security group for kubernetes worker nodes"
}

resource "exoscale_security_group_rules" "worker-rules" {
  security_group_id = "${exoscale_security_group.worker-sg.id}"

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
  # harbor nodeport (temporary)
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["30000-30010"]
  }
  # Allow all internal communication
  ingress {
    protocol = "TCP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
    ]
  }
  ingress {
    protocol = "UDP"
    ports    = ["0-65535"]
    user_security_group_list = [
      "${var.master_security_group_name}",
      "${var.worker_security_group_name}",
    ]
  }
}

resource "exoscale_ipaddress" "e-ip" {
  zone                     = "de-fra-1"
  healthcheck_mode         = "http"
  healthcheck_port         = 10254
  healthcheck_path         = "/healthz"
  healthcheck_interval     = 10
  healthcheck_timeout      = 2
  healthcheck_strikes_ok   = 2
  healthcheck_strikes_fail = 3
}

resource "exoscale_secondary_ipaddress" "e-ip-1" {
  compute_id = "${exoscale_compute.worker1.id}"
  ip_address = "${exoscale_ipaddress.e-ip.ip_address}"
}

resource "exoscale_secondary_ipaddress" "e-ip-2" {
  compute_id = "${exoscale_compute.worker2.id}"
  ip_address = "${exoscale_ipaddress.e-ip.ip_address}"
}

resource "exoscale_ssh_keypair" "ssh_key" {
  name       = "${var.ssh_key_name}"
  public_key = file(pathexpand("${var.ssh_pub_key_file}"))
}
