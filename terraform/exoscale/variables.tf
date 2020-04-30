# Exoscale credentials.
variable exoscale_api_key {
  description = "Either use .cloudstack.ini or this to set the API key."
  type        = string
}

variable exoscale_secret_key {
  description = "Either use .cloudstack.ini or this to set the API secret."
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
  default = "CK8S BaseOS v0.0.6"
}

# For workers

variable worker_names_sc {
  description = "List of names for worker instances to create."
  type        = list(string)

  default = ["worker-0", "worker-1"]
}

variable worker_name_size_map_sc {
  description = "Map of instance name to openstack size."
  type        = map

  default = {
    "worker-0" : "Extra-large",
    "worker-1" : "Large"
  }
}

variable worker_names_wc {
  description = "List of names for worker instances to create."
  type        = list(string)

  default = ["worker-0", "worker-1"]
}

variable worker_name_size_map_wc {
  description = "Map of instance name to openstack size."
  type        = map

  default = {
    "worker-0" : "Large",
    "worker-1" : "Large"
  }
}

# For masters
variable master_names_sc {
  description = "List of names for master instances to create."
  type        = list(string)
  default     = ["master-0"]
}

variable master_name_size_map_sc {
  description = "Map of instance name to openstack size."
  type        = map
  default = {
    "master-0" : "Small"
  }
}

variable master_names_wc {
  description = "List of names for master instances to create."
  type        = list(string)
  default     = ["master-0"]
}

variable master_name_size_map_wc {
  description = "Map of instance name to openstack size."
  type        = map
  default = {
    "master-0" : "Small"
  }
}

variable nfs_size {
  description = "The size of the nfs machine"
  type        = string
  default     = "Small"
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

variable dns_prefix {
  description = "Prefix name for dns"
  type        = string
}

variable es_local_storage_capacity_map_sc {
  description = "Map of the size in GB of the Elasticsearch node local storage file system."
  type        = map

  default = {
    "worker-0" : "26",
    "worker-1" : "26"
  }
}

variable es_local_storage_capacity_map_wc {
  description = "Map of the size in GB of the Elasticsearch node local storage file system."
  type        = map

  default = {
    "worker-0" : "0"
  }
}
