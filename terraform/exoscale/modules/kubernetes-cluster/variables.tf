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

variable "ssh_pub_key" {}

variable "public_ingress_cidr_whitelist" {
  type = list(string)
}

variable "api_server_whitelist" {
  type = list(string)
}

variable "private_network_cidr" {
  default = "172.0.10.0/24"
}

variable "compute_instance_image" {}

## DNS
variable "dns_list" {
  type = list(string)
}

variable "dns_suffix" {}

variable "dns_prefix" {}

variable "aws_dns_zone_id" {
  default = "Z2STJRQSJO5PZ0" # elastisys.com
}

variable "role_arn" {
  default = "arn:aws:iam::248119176842:role/a1-pipeline"
}

variable es_local_storage_capacity_map {
  description = "Map of the size in GB of the Elasticsearch node local storage file system."
  type        = map
}
