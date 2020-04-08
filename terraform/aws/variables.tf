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

variable worker_nodes_sc {
  description = "Map of instance name to EC2 instance type."
  type        = map

  default = {
    "worker-0" : "t3.small"
  }
}

variable worker_nodes_wc {
  description = "Map of instance name to EC2 instance type."
  type        = map

  default = {
    "worker-0" : "t3.small"
  }
}

variable master_nodes_sc {
  description = "Map of instance name to EC2 instance type."
  type        = map

  default = {
    "master-0" : "t3.small"
  }
}

variable master_nodes_wc {
  description = "Map of instance name to EC2 instance type."
  type        = map

  default = {
    "master-0" : "t3.small"
  }
}

# BaseOS
# us-west-1_1.17.2  = ami-08f7e448df967347b
# us-west-1_1.15.10 = ami-0791b6074a5a010ee
variable aws_amis {
  type = map
  default = {
    # us-west-1, kubernetes v1.15.10
    "sc_master" = "ami-0791b6074a5a010ee"
    "sc_worker" = "ami-0791b6074a5a010ee"
    "wc_master" = "ami-0791b6074a5a010ee"
    "wc_worker" = "ami-0791b6074a5a010ee"
  }
}
