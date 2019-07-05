provider "exoscale" {
  version = "~> 0.11"
  key     = "${var.exoscale_api_key}"
  secret  = "${var.exoscale_secret_key}"

  timeout = 120 # default: waits 60 seconds in total for a resource
}


resource "exoscale_compute" "master" {
  display_name    = "master"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.tf-key2.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.master-sg2.name}"]
}

resource "exoscale_compute" "worker1" {
  display_name    = "worker1"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.tf-key2.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.worker-sg2.name}"]
}

resource "exoscale_compute" "worker2" {
  display_name    = "worker2"
  template        = "Linux RancherOS 1.5.1 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.tf-key2.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.worker-sg2.name}"]
}



resource "exoscale_security_group" "master-sg2" {
  name        = "master-sg2"
  description = "security group for kubernetes masters"
}

resource "exoscale_security_group_rules" "master-rules" {
  security_group_id = "${exoscale_security_group.master-sg2.id}"

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
    user_security_group_list = ["master-sg2", "worker-sg2"]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = ["master-sg2", "worker-sg2"]
  }

  # Master specific ports
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }
}


resource "exoscale_security_group" "worker-sg2" {
  name        = "worker-sg2"
  description = "security group for kubernetes worker nodes"
}

resource "exoscale_security_group_rules" "worker-rules" {
  security_group_id = "${exoscale_security_group.worker-sg2.id}"

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
    user_security_group_list = ["master-sg2", "worker-sg2"]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = ["master-sg2", "worker-sg2"]
  }
}


resource "exoscale_ipaddress" "e_ip" {
  zone = "de-fra-1"
  tags = {
    usage = "load-balancer"
  }
}


resource "exoscale_secondary_ipaddress" "e_ip_1" {
  compute_id = "${exoscale_compute.worker1.id}"
  ip_address = "${exoscale_ipaddress.e_ip.ip_address}"
}

resource "exoscale_secondary_ipaddress" "e_ip_2" {
  compute_id = "${exoscale_compute.worker2.id}"
  ip_address = "${exoscale_ipaddress.e_ip.ip_address}"
}

resource "exoscale_ssh_keypair" "tf-key2" {
  name       = "tf-key2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWB9CPyyrL2AS/WpMw+4MQ6IUT7dOyC/48Rv1xhNAcUYUetBa7IuSv3E6sF4qaVOYfyWu6zZstj+JwOlJd0l7vIg4Eu/wjc1A8IdEfBDQwRCTXDub5yRUtlSGWlygy0lhSJXOnWhMspSVefJ6VxSCK6Lvwg0wtwZrC8Zm1tBnHOC+tGBQ9ibiPySMaIzGkUttA0Tc71HfwuYVDdmRhjlUJ5UJdJrvdGk3ApLCR6/4xiQKL1ht9fv0sAB7V3o3tWvGOWjQQwFyF41E3FV0X5f03pOx3nRVb4MNJ5/sZaXsMUKLlalHfPoVDoakRVIqf4myz4TnvXeBE7uv+oB+CmzzN"
}