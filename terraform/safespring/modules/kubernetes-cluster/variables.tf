variable "prefix" {}
variable "image_id" {}
variable "key_pair" {}
variable public_v4_network {}
variable k8s_version {
  description = "Kubernetes version. Valid versions: 1.15.11"
  default     = "1.15.11"
}

## DNS

#variable "dns_name" {}
variable "dns_list" {
  type = list(string)
}

variable "aws_dns_zone_id" {
  default = "Z2STJRQSJO5PZ0" # elastisys.se
}

variable "role_arn" {
  default = "arn:aws:iam::248119176842:role/a1-pipeline"
}

# For workers
variable "worker_name_flavor_map" {
  type = map
}

variable "worker_names" {
  type = list(string)
}


# For masters
variable "master_name_flavor_map" {
  type = map
}

variable "master_names" {
  type = list(string)
}

variable "loadbalancer_names" {
  description = "List of names for loadbalancer instances to create."
  type        = list(string)
  default     = []
}

variable "loadbalancer_name_flavor_map" {
  description = "Map of instance name to openstack flavor."
  type        = map
  default     = {}
}

variable public_ingress_cidr_whitelist {
  type = string
}
