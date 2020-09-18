variable "prefix" {
  type = string
}

variable "ssh_pub_key" {
  description = "Path to public SSH key file which is injected into the VMs."
  type        = string
}

variable public_ingress_cidr_whitelist {
  type = list
}

variable api_server_whitelist {
  type = list
}

variable nodeport_whitelist {
  type = list
}

variable external_network_id {
  description = "the id of the external network"
  type        = string
}

variable external_network_name {
  description = "the name of the external network"
  type        = string
}

variable machines {
  type = map(object({
    node_type = string
    size      = string
    image     = string
  }))
}

variable "master_anti_affinity_policy" {
  description = "This can be set to 'anti-affinity' to spread out masters on different physical machines, otherwise leave it empty"
  type        = string
}

variable "worker_anti_affinity_policy" {
  description = "This can be set to 'anti-affinity' to spread out workers on different physical machines, otherwise leave it empty"
  type        = string
}

# For DNS
variable "dns_list" {
  type = list(string)
}

variable "dns_prefix" {}

variable "aws_dns_zone_id" {
  type = string
}

variable "aws_dns_role_arn" {
  type = string
}
