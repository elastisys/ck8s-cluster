
variable "image_id" {}
variable "key_pair" {}
variable "network_id" {}
variable "subnet_id" {}
variable "prefix" {}

variable "security_group_ids" {
  type = list(string)
}

variable "name_flavor_map" {
  description = "Mapping from instance name to openstack flavor."
  type        = map
}

variable "names" {
  description = "List of names for instances to be created."
  type        = list(string)
}

variable external_network_name {
  description = "the name of the external network"
  type        = string
}

variable "server_group_id" {
  description = "Id to the servergroup these instances should belong to."
  type        = string
}
