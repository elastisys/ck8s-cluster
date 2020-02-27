variable "region" {
  type    = string
  default = "us-west-1"
}

variable "public_ingress_cidr_whitelist" {
  type = list(string)
}

variable "prefix_sc" {
  type = string
}

variable "prefix_wc" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "sc_key_name" {
  type = string
}

variable "wc_key_name" {
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
    "worker-0" : "t3.small",
    "worker-1" : "t3.small"
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
