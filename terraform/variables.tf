# Exoscale credentials.
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


# Service cluster variables.
variable ssh_pub_key_file_sc {
  description = "Path to public SSH key file which is injected into the VMs."

  type = string
}

variable sc_master_count {
  description = "The number of master nodes that should be created."

  type = number
  default = 1
}

variable sc_master_size {
  description = "The size of the master VMs"

  type = string
  default = "Large"
}

variable sc_worker_count {
  description = "The number of worker nodes that should be created."

  type    = number
  default = 1
}

variable sc_worker_size {
  description = "The size of the worker VMs."

  type = string
  default = "Extra-large"
}


# Workload cluster variables.
variable ssh_pub_key_file_wc {
  description = "Path to public SSH key file which is injected into the VMs."

  type = string
}

variable wc_master_count {
  description = "The number of master nodes that should be created."

  type = number
  default = 1
}

variable wc_master_size {
  description = "The size of the master VMs."

  type = string
  default = "Large"
}

variable wc_worker_count {
  description = "The number of worker nodes that should be created."

  type    = number
  default = 1
}

variable wc_worker_size {
  description = "The size of the worker VMs."

  type = string
  default = "Large"
}


# Common variables.
variable "public_ingress_cidr_whitelist" {
  type    = list(string)
  default = ["212.32.186.85/32", "193.187.219.4/32"] # Elastisys office, A1 office
}

variable "dns_prefix" {
  description = "Prefix name for dns"
  type        = string
}
