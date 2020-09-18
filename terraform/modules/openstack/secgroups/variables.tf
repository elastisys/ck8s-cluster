variable "prefix" {
  type = string
}

variable public_ingress_cidr_whitelist {
  type = list
}

variable api_server_whitelist {
  type = list
}

variable nodeport_whitelist {
  type = list
}
