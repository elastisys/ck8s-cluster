variable ssh_pub_key_file_sc {
  description = "Path to public SSH key file which is injected into the VMs."

  type = string
}

variable ssh_pub_key_file_wc {
  description = "Path to public SSH key file which is injected into the VMs."

  type = string
}

variable "dns_prefix" {
  description = "Prefix name for dns"
  type        = string
}

variable sc_master_count {
  description = "The number of master nodes that should be created."
  type        = number
  default     = 1
}

variable sc_worker_count {
  description = "The number of worker nodes that should be created."
  type        = number
  default     = 2
}

variable wc_master_count {
  description = "The number of master nodes that should be created."
  type        = number
  default     = 1
}

variable wc_worker_count {
  description = "The number of worker nodes that should be created."
  type        = number
  default     = 1
}