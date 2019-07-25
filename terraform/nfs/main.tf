# terraform {
#   backend "remote" {
#     hostname     = "app.terraform.io"
#     organization = "elastisys"

#     workspaces {
#       prefix = "a1-demo-nfs"
#     }
#   }
# }

provider "exoscale" {
  version = "~> 0.11"
  key     = "${var.exoscale_api_key}"
  secret  = "${var.exoscale_secret_key}"

  timeout = 120 # default: waits 60 seconds in total for a resource
}

resource "exoscale_compute" "nfs" {
  display_name    = "${terraform.workspace}-nfs-storage"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Large"
  disk_size       = 50
  key_pair        = "${exoscale_ssh_keypair.ssh_key.name}"
  state           = "Running"
  zone            = "de-fra-1"
  security_groups = ["${exoscale_security_group.nfs-sg.name}"]
}

resource "exoscale_security_group" "nfs-sg" {
  name        = "${terraform.workspace}-nfs-storage-sg"
  description = "Security group for nfs"
}

resource "exoscale_security_group_rules" "nfs-rules" {
  security_group_id = "${exoscale_security_group.nfs-sg.id}"

  # SSH
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["22"]
  }

  # nfs specific ports
  ingress {
    protocol  = "TCP"
    cidr_list = ["0.0.0.0/0"]
    ports     = ["6443"]
  }
}

resource "exoscale_ssh_keypair" "ssh_key" {
  name       = "${terraform.workspace}-nfs-storage-ssh-key"
  public_key = file(pathexpand("${var.ssh_pub_key_file}"))
}

/nfs 89.145.160.200(rw,sync,no_subtree_check) 89.145.162.84(rw,sync,no_subtree_check)
