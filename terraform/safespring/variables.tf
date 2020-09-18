variable ssh_pub_key_sc {
  description = "Path to public SSH key file which is injected into the VMs."
  type        = string
}

variable ssh_pub_key_wc {
  description = "Path to public SSH key file which is injected into the VMs."
  type        = string
}

variable dns_prefix {
  description = "Prefix name for dns"
  type        = string
}

variable aws_dns_zone_id {
  description = "Id for the AWS DNS zone"
  type        = string
}

variable aws_dns_role_arn {
  description = "AWS role to asume while creating DNS entries"
  type        = string
}

variable prefix_sc {
  description = "Prefix for resource names"
  default     = ""
}

variable prefix_wc {
  description = "Prefix for resource names"
  default     = ""
}

variable machines_sc {
  type = map(object({
    node_type = string
    size      = string
    image     = string
  }))
}

variable machines_wc {
  type = map(object({
    node_type = string
    size      = string
    image     = string
  }))
}

variable "worker_anti_affinity_policy_sc" {
  description = "This can be set to 'anti-affinity' to spread out workers on different physical machines, otherwise leave it empty"
  type        = string
}

variable "worker_anti_affinity_policy_wc" {
  description = "This can be set to 'anti-affinity' to spread out workers on different physical machines, otherwise leave it empty"
  type        = string
}

variable "master_anti_affinity_policy_sc" {
  description = "This can be set to anti-affinity to spread out masters on different physical machines, otherwise leave it empty"
  type        = string
}

variable "master_anti_affinity_policy_wc" {
  description = "This can be set to anti-affinity to spread out masters on different physical machines, otherwise leave it empty"
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
