terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "elastisys"

    workspaces {
      prefix = "a1-demo-system-services-"
    }
  }
}

provider "exoscale" {
  version = "~> 0.11"
  key     = "${var.exoscale_api_key}"
  secret  = "${var.exoscale_secret_key}"

  timeout = 120 # default: waits 60 seconds in total for a resource
}

locals {
  master_security_group_name = "${terraform.workspace}-ss-master-sg"
  worker_security_group_name = "${terraform.workspace}-ss-worker-sg"
}

resource "exoscale_compute" "ss-master" {
  display_name    = "${terraform.workspace}-ss-master"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ss-tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.ss-master-sg.name}"]
}

resource "exoscale_compute" "ss-worker1" {
  display_name    = "${terraform.workspace}-ss-worker1"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ss-tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.ss-worker-sg.name}"]
}

resource "exoscale_compute" "ss-worker2" {
  display_name    = "${terraform.workspace}-ss-worker2"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ss-tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.ss-worker-sg.name}"]
}



resource "exoscale_security_group" "ss-master-sg" {
  name        = "${local.master_security_group_name}"
  description = "security group for kubernetes masters"
}

resource "exoscale_security_group_rules" "ss-master-rules" {
  security_group_id = "${exoscale_security_group.ss-master-sg.id}"

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["22"]
  }
  # Allow all internal communication
  ingress {
    protocol                 = "TCP"
    ports                    = ["0-65535"]
    user_security_group_list = [
      "${local.master_security_group_name}",
      "${local.worker_security_group_name}",
    ]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = [
      "${local.master_security_group_name}",
      "${local.worker_security_group_name}",
    ]
  }

  # Master specific ports
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }
}


resource "exoscale_security_group" "ss-worker-sg" {
  name        = "${local.worker_security_group_name}"
  description = "security group for kubernetes worker nodes"
}

resource "exoscale_security_group_rules" "ss-worker-rules" {
  security_group_id = "${exoscale_security_group.ss-worker-sg.id}"

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
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
    protocol                 = "TCP"
    ports                    = ["0-65535"]
    user_security_group_list = [
      "${local.master_security_group_name}",
      "${local.worker_security_group_name}",
    ]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = [
      "${local.master_security_group_name}",
      "${local.worker_security_group_name}",
    ]
  }
}


resource "exoscale_ipaddress" "ss-e-ip" {
  zone                     = "de-fra-1"
  healthcheck_mode         = "http"
  healthcheck_port         = 10254
  healthcheck_path         = "/healthz"
  healthcheck_interval     = 10
  healthcheck_timeout      = 2
  healthcheck_strikes_ok   = 2
  healthcheck_strikes_fail = 3
}

resource "exoscale_secondary_ipaddress" "ss-e-ip-1" {
  compute_id = "${exoscale_compute.ss-worker1.id}"
  ip_address = "${exoscale_ipaddress.ss-e-ip.ip_address}"
}

resource "exoscale_secondary_ipaddress" "ss-e-ip-2" {
  compute_id = "${exoscale_compute.ss-worker2.id}"
  ip_address = "${exoscale_ipaddress.ss-e-ip.ip_address}"
}

resource "exoscale_ssh_keypair" "ss-tf-key" {
  name       = "${terraform.workspace}-ss-tf-key"
  public_key = file(pathexpand("${var.ssh_pub_key_file}"))
}
