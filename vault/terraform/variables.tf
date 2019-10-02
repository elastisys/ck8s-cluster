# Exoscale credentials.
variable exoscale_api_key {
  description = "Either use .cloudstack.ini or this to set the API key."
  type        = string
  default     = ""
}

variable exoscale_secret_key {
  description = "Either use .cloudstack.ini or this to set the API secret."
  type        = string
  default     = ""
}


# Service cluster variables.
variable ssh_pub_key_file_vault {
  description = "Path to public SSH key file which is injected into the VMs."
  type        = string
}

variable vault_master_count {
  description = "The number of master nodes that should be created."
  type        = number
  default     = 1
}

variable vault_master_size {
  description = "The size of the master VMs"
  type        = string
  default     = "Medium"
}

variable vault_nfs_size {
  description = "The size of the nfs machine"
  type        = string
  default     = "Small"
}


# Common variables.
variable "public_ingress_cidr_whitelist" {
  type    = list(string)
  default = ["194.132.164.168/32", "194.132.164.169/32", "193.187.219.4/32"] # Elastisys office, A1 office
}

variable "dns_prefix" {
  description = "Prefix name for dns"
  type        = string
}
