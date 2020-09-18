variable region {
  default = "us-west-1"
}

variable aws_access_key {
  description = "AWS API access key"
  type        = string
}

variable aws_secret_key {
  description = "AWS API secret key"
  type        = string
}

variable public_ingress_cidr_whitelist {
  type = list(string)
}

variable api_server_whitelist {
  type = list(string)
}

variable nodeport_whitelist {
  type = list(string)
}

variable prefix_sc {
  type = string
}

variable prefix_wc {
  type = string
}

variable ssh_pub_key_sc {
  type = string
}

variable ssh_pub_key_wc {
  type = string
}

variable machines_sc {
  type = map(object({
    node_type = string
    size      = string
    image     = string
  }))
}

variable machines_wc {
  type = map(object({
    node_type = string
    size      = string
    image     = string
  }))
}
