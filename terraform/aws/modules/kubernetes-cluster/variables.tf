variable "prefix" {}

variable "public_ingress_cidr_whitelist" {
  type = list(string)
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-west-1"
}

variable "ssh_pub_key" {
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
  default     = "1.15.10"
}
