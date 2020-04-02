variable "prefix" {}
variable "image_id" {}
variable "key_pair" {}
variable public_v4_network {}
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

# Configuration of instance that should mount an extra volume
variable "worker_extra_volume" {
  type    = list(string)
  default = []
}

variable "worker_extra_volume_size" {
  type    = map
  default = {}
}
