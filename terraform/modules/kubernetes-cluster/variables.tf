variable "master_name" {}

variable "worker_1_name" {}

variable "worker_2_name" {}

variable "master_security_group_name" {}

variable "worker_security_group_name" {}

variable "ssh_key_name" {}

variable "ssh_pub_key_file" {}

variable "public_ingress_cidr_whitelist" {
  type    = list(string)
  default = ["212.32.186.85/32"] # Elastisys office
}
