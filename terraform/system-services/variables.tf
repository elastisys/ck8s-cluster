variable exoscale_api_key {
  description = "Either use .cloudstack.ini or this to set the API key."

  type    = string
  default = ""
}

variable exoscale_secret_key {
  description = "Either use .cloudstack.ini or this to set the API secret."

  type    = string
  default = ""
}

variable ssh_pub_key_file_ss {
  description = "Path to public SSH key file which is injected into the VMs."

  type = string
}

variable worker_count {
  description = "The number of worker nodes that should be created."

  type    = number
  default = 2
}

variable "public_ingress_cidr_whitelist" {
  type    = list(string)
  default = ["212.32.186.85/32"] # Elastisys office
}

variable "dns_prefix" {
  description = "Prefix name for dns"
  type = string
}
