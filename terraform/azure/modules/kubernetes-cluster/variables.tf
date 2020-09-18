variable "location" {
  type = string
  # TODO Do we want to use this as default?
  default = "North Europe"
}

variable "prefix" {}

variable "machines" {
  type = map(object({
    node_type = string
    size      = string
  }))
}

variable "ssh_pub_key" {}

variable "public_ingress_cidr_whitelist" {
  type = list(string)
}

variable "api_server_whitelist" {
  type = list(string)
}

variable "nodeport_whitelist" {
  type = list(string)
}

variable "private_network_cidr" {
  default = "10.0.0.0/16"
}

variable "compute_instance_image" {}

## DNS
variable "dns_list" {
  type = list(string)
}

variable "dns_suffix" {}

variable "dns_prefix" {}
