variable "prefix" {
  type = string
}

variable "ssh_pub_key" {
  description = "Path to public SSH key file which is injected into the VMs."
  type        = string
}

variable "cluster_image" {
  description = "id of image to use for worker and master VMs"
  type        = string
}

variable public_ingress_cidr_whitelist {
  type = string
}

variable external_network_id {
  description = "the id of the external network"
  type        = string
}

variable external_network_name {
  description = "the name of the external network"
  type        = string
}

# For masters
variable "master_names" {
  type = list(string)
}

variable "master_name_flavor_map" {
  type = map
}

# For workers
variable "worker_names" {
  type = list(string)
}

variable "worker_name_flavor_map" {
  type = map
}

# For loadbalancers
variable "octavia_names" {
  type = list(string)
}

# For DNS
variable "dns_list" {
  type = list(string)
}

variable "aws_dns_zone_id" {
  type = string
}

variable "aws_dns_role_arn" {
  type = string
}
