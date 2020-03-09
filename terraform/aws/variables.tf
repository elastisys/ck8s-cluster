variable region {
  default = "us-west-1"
}

variable infra_credentials_file_path {
  description = "Path to credentials file, passed to pathexpand"
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

variable k8s_version {
  description = "Kubernetes version. Valid versions: 1.15.10, 1.17.2"
  default     = "1.15.10"
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
