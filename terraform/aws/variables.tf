variable region {
  default = "eu-west-1"
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

variable prefix {
  type = string
}

variable ssh_pub_key {
  type = string
}

variable machines {
  type = map(object({
    node_type = string
    size      = string
    image = object({
      name = string
    })
  }))
}

variable extra_tags {
  default = {
  }
  description = "Any extra tags that should be present on each EC2 instance"
  type        = map(string)
}
