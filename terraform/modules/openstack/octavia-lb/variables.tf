
variable "subnet_id" {}

variable "worker_ips" {
}

variable "names" {
  description = "List of names for instances to be created."
  type        = set(string)
}

variable external_network_name {
  description = "the name of the external network"
  type        = string
}