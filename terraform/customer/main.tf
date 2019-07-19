terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "elastisys"

    workspaces {
      name = "a1-demo-customer"
    }
  }
}

provider "exoscale" {
  version = "~> 0.11"
  key     = "${var.exoscale_api_key}"
  secret  = "${var.exoscale_secret_key}"

  timeout = 120 # default: waits 60 seconds in total for a resource
}

resource "exoscale_compute" "c-master" {
  display_name    = "c-master"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.c-tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.c-master-sg.name}"]

  provisioner "file" {
    source      = "${path.module}/../../manifests/pod-node-restriction/admission-control-config.yaml"
    destination = "/home/rancher/admission-control-config.yaml"

    connection {
      type     = "ssh"
      user     = "rancher"
      host     = "${self.ip_address}"
    }
  }

  provisioner "file" {
    source      = "${path.module}/../../manifests/pod-node-restriction/podnodeselector.yaml"
    destination = "/home/rancher/podnodeselector.yaml"

    connection {
      type     = "ssh"
      user     = "rancher"
      host     = "${self.ip_address}"
    }
  }
}

resource "exoscale_compute" "c-worker1" {
  display_name    = "c-worker1"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.c-tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.c-worker-sg.name}"]
}

resource "exoscale_compute" "c-worker2" {
  display_name    = "c-worker2"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.c-tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.c-worker-sg.name}"]
}

resource "exoscale_security_group" "c-master-sg" {
  name        = "c-master-sg"
  description = "security group for kubernetes masters"
}

resource "exoscale_security_group_rules" "c-master-rules" {
  security_group_id = "${exoscale_security_group.c-master-sg.id}"

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
    user_security_group_list = ["c-master-sg", "c-worker-sg"]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = ["c-master-sg", "c-worker-sg"]
  }

  # Master specific ports
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }
}


resource "exoscale_security_group" "c-worker-sg" {
  name        = "c-worker-sg"
  description = "security group for kubernetes worker nodes"
}

resource "exoscale_security_group_rules" "c-worker-rules" {
  security_group_id = "${exoscale_security_group.c-worker-sg.id}"

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
    user_security_group_list = ["c-master-sg", "c-worker-sg"]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = ["c-master-sg", "c-worker-sg"]
  }
}


resource "exoscale_ipaddress" "c-e-ip" {
  zone                     = "de-fra-1"
  healthcheck_mode         = "http"
  healthcheck_port         = 10254
  healthcheck_path         = "/healthz"
  healthcheck_interval     = 10
  healthcheck_timeout      = 2
  healthcheck_strikes_ok   = 2
  healthcheck_strikes_fail = 3
}

resource "exoscale_secondary_ipaddress" "c-e-ip-1" {
  compute_id = "${exoscale_compute.c-worker1.id}"
  ip_address = "${exoscale_ipaddress.c-e-ip.ip_address}"
}

resource "exoscale_secondary_ipaddress" "c-e-ip-2" {
  compute_id = "${exoscale_compute.c-worker2.id}"
  ip_address = "${exoscale_ipaddress.c-e-ip.ip_address}"
}

resource "exoscale_ssh_keypair" "c-tf-key" {
  name       = "c-tf-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXVVRRglwnNbnhqsFcMCnQUVO172AiU0WNSwN7RVzjHtS4LxWaq2hmz2af/wE1+ysxHuyWJmV7RkOP1PtLC1vjDI0ly0xjqW9oZovqezF7M/p++ofD8iMTHs66FINgjP85i0G8Twu9pc1akdGSAJ314isAAzO3ojcSf2G4DGGTTUaZG2tgoZYx4x4mEXRznBu3dYeA3/sbAtrPmWaXryq0wt9lg1Y5cp7k1H9n6q76t8UXgGJ/T/EOU8AAPZElPhBzcFXWwvtQn5qcUh/G8sGgbKtKAJ13e2FFR3tMZb1qKl9JCpu/UNuKp/vO5K87tXbwUPFw/qrRygzHBHX9Uc3j erik@erik-XPS-13-9380"
}