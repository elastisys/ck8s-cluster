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

variable "key_name" {
  description = "Desired name of AWS key pair"
}

# Ubuntu 18.04 LTS
variable "aws_amis" {
  default = {
    us-west-1 = "ami-08fc2905b265936b7"
    us-west-2 = "ami-03392f4dbaa105b49"
    us-east-1 = "ami-0966b6f5f146f738b"
    us-east-2 = "ami-04ba6a052833f9870"
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
