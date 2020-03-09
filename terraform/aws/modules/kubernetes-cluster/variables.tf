variable prefix {
  type = string
}

variable public_ingress_cidr_whitelist {
  type = list(string)
}

variable aws_region {
  description = "AWS region"
  type        = string
}

variable "ssh_pub_key" {
  description = "Path to the SSH public key to be used for authentication"
}

# BaseOS
variable aws_amis {
  default = {
    "us-west-1_1.17.2"  = "ami-08f7e448df967347b"
    "us-west-1_1.15.10" = "ami-0791b6074a5a010ee"
  }
}

variable worker_nodes {
  description = "Map of instance name to EC2 instance type."
  type        = map
}

variable master_nodes {
  description = "Map of instance name to EC2 instance type."
  type        = map
}

variable k8s_version {
  description = "Kubernetes version. Valid versions: 1.15.10, 1.17.2"
}
