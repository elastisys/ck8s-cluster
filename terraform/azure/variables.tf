variable subscription_id {
  description = ""
  type        = string
}
variable tenant_id {
  description = ""
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

variable "compute_instance_image" {
  default = "CK8S_Base_OS_v0.0.7"
}

variable machines_sc {
  description = "Service cluster machines"
  type = map(object({
    node_type = string
    size      = string
  }))
}

variable machines_wc {
  description = "Workload cluster machines"
  type = map(object({
    node_type = string
    size      = string
  }))
}

variable ssh_pub_key_sc {
  description = "Path to public SSH key file which is injected into the VMs."
  type        = string
}

variable ssh_pub_key_wc {
  description = "Path to public SSH key file which is injected into the VMs."
  type        = string
}

variable public_ingress_cidr_whitelist {
  type = list(string)
}

variable api_server_whitelist {
  type = list(string)
}

variable nodeport_whitelist {
  type = list(string)
}

variable dns_prefix {
  description = "Prefix name for dns"
  type        = string
}
