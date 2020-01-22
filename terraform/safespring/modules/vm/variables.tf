
variable "image_id" {}
variable "key_pair" {}
variable "network_id" {}
variable "subnet_id" {}
variable "security_group_ids" {
  type = list(string)
}

variable "name_flavor_map" {
  description = "Mapping from instance name to openstack flavor."
  type        = map
}

variable "names" {
  description = "List of names for instances to be created."
  type = list(string)
}

