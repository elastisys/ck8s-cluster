variable "zone" {
  type = string
  # This is currently the only zone that is supposed to be supporting
  # so called "managed private networks".
  # See: https://www.exoscale.com/syslog/introducing-managed-private-networks
  default = "ch-gva-2"
}

variable "prefix" {}

variable "worker_names" {
  type = list(string)
}

variable "worker_name_size_map" {
  type = map
}

variable "master_names" {
  type = list(string)
}

variable "master_name_size_map" {
  type = map
}

variable "nfs_size" {}

variable "ssh_pub_key_file" {}

variable "public_ingress_cidr_whitelist" {
  type = list(string)
}

variable "compute_instance_image" {
  default = "CK8S BaseOS v0.0.4"
}

## DNS
variable "dns_list" {
  type = list(string)
}

variable "dns_suffix" {}

variable "aws_dns_zone_id" {
  default = "Z2STJRQSJO5PZ0" # elastisys.com
}

variable "role_arn" {
  default = "arn:aws:iam::248119176842:role/a1-pipeline"
}
