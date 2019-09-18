variable "zone" {
  type = string
  # This is currently the only zone that is supposed to be supporting
  # so called "managed private networks".
  # See: https://www.exoscale.com/syslog/introducing-managed-private-networks
  default = "ch-gva-2"
}

variable "network_name" {}

variable "master_name" {}

variable "worker_name" {}

variable "worker_count" {}

variable "worker_size" {}

variable "nfs_name" {}

variable "master_security_group_name" {}

variable "worker_security_group_name" {}

variable "nfs_security_group_name" {}

variable "ssh_key_name" {}

variable "ssh_pub_key_file" {}

variable "public_ingress_cidr_whitelist" {
  type    = list(string)
  default = ["212.32.186.85/32", "193.187.219.4/32"] # Elastisys office
}

## DNS

variable "dns_name" {}

variable "aws_dns_zone_id" {
  default = "Z2A7G3OHZDNUQ1" #compliantkubernetes.com
}

variable "role_arn" {
  default = "arn:aws:iam::248119176842:role/a1-pipeline"
}

