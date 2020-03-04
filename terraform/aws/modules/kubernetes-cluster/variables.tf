variable "prefix" {}

variable "public_ingress_cidr_whitelist" {
  type = list(string)
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-west-1"
}

variable "public_key_path" {
  description = "Path to the SSH public key to be used for authentication"
}

variable "private_key_path" {
  description = "Path to the SSH private key to be used for authentication"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

# BaseOS
variable "aws_amis" {
  default = {
    us-west-1 = "ami-08f7e448df967347b"
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
