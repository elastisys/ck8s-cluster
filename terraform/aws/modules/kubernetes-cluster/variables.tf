variable prefix {
  type = string
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

variable aws_region {
  description = "AWS region"
  type        = string
}

variable "ssh_pub_key" {
  description = "Path to the SSH public key to be used for authentication"
}

variable machines {
  type = map(object({
    node_type = string
    size      = string
    image     = string
  }))
}
