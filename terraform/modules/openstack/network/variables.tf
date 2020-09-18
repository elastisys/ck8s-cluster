variable "prefix" {
  type = string
}

variable external_network_id {
  description = "the id of the external network"
  type        = string
}

variable subnet_cidr {
  type = string
}
