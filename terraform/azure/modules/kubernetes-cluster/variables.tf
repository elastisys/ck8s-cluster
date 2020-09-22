variable "location" {
  type = string
}

variable "prefix" {}

variable "machines" {
  type = map(object({
    node_type = string
    size      = string
    image = object({
      name = string
    })
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
  default = "10.0.10.0/24"
}

## DNS
variable "dns_list" {
  type = list(string)
}

variable "dns_suffix" {}

variable "dns_prefix" {}
