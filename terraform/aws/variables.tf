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

# BaseOS 0.0.6, US West 1, k8s 1.15.11
# ami-025fd2f1456a0e2e5
variable aws_amis {
  type = map
  default = {
    "sc_master" = "ami-025fd2f1456a0e2e5"
    "sc_worker" = "ami-025fd2f1456a0e2e5"
    "wc_master" = "ami-025fd2f1456a0e2e5"
    "wc_worker" = "ami-025fd2f1456a0e2e5"
  }
}
