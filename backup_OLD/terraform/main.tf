provider "exoscale" {
  version = "~> 0.11"
  key     = "${var.exoscale_api_key}"
  secret  = "${var.exoscale_secret_key}"

  timeout = 120 # default: waits 60 seconds in total for a resource
}


resource "exoscale_compute" "master" {
  display_name    = "master"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Medium"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.master-sg.name}"]
}

resource "exoscale_compute" "worker1" {
  display_name    = "worker1"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Medium"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.worker-sg.name}"]
}

resource "exoscale_compute" "worker2" {
  display_name    = "worker2"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Medium"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.tf-key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.worker-sg.name}"]
}



resource "exoscale_security_group" "master-sg" {
  name        = "master-sg"
  description = "security group for kubernetes masters"
}

resource "exoscale_security_group_rules" "master-rules" {
  security_group_id = "${exoscale_security_group.master-sg.id}"

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
    user_security_group_list = ["master-sg", "worker-sg"]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = ["master-sg", "worker-sg"]
  }

  # Master specific ports
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }
}


resource "exoscale_security_group" "worker-sg" {
  name        = "worker-sg"
  description = "security group for kubernetes worker nodes"
}

resource "exoscale_security_group_rules" "worker-rules" {
  security_group_id = "${exoscale_security_group.worker-sg.id}"

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
    user_security_group_list = ["master-sg", "worker-sg"]
  }
  ingress {
    protocol                 = "UDP"
    ports                    = ["0-65535"]
    user_security_group_list = ["master-sg", "worker-sg"]
  }
}

resource "exoscale_ssh_keypair" "tf-key" {
  name       = "tf-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCuM/m+DGxRGWUiQwUm8kKTqJTBLqhH8O+bZLrDOZKoW96JZ1KUAYaWjEdR8TW0rufq8I3TElxYwwIYNcxAVnQdKp4a2ZTK96DRLog9q7ObibTR9SRtIQY/dlHFEp6zQcEUrk1CECyJXx8DiIyrdXnClbuUJs7ZOCHMD+Qef2gdkQ=="
}
