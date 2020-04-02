variable ssh_pub_key_file_sc {
  description = "Path to public SSH key file which is injected into the VMs."

  type = string
}

variable ssh_pub_key_file_wc {
  description = "Path to public SSH key file which is injected into the VMs."

  type = string
}

variable dns_prefix {
  description = "Prefix name for dns"
  type        = string
}

variable "prefix_sc" {
  description = "Prefix for resource names"
  default     = ""
}

variable "prefix_wc" {
  description = "Prefix for resource names"
  default     = ""
}

# For workers
# Common flavors
# 393f905d-86af-4b70-a03a-f6757f66721e 1 2gb 50gb
# 89afeed0-9e41-4091-af73-727298a5d959 2 4gb 50gb
# ecd976c3-c71c-4096-b138-e4d964c0b27f 4 8gb 50gb
# 820fb969-597f-416f-b03f-1476349813d2 2 8gb 50gb
# f6a5e4d3-203d-45c0-a36a-dc5538580e1a 4 16gb 50gb
variable worker_names_sc {
  description = "List of names for worker instances to create."
  type        = list(string)

  default = ["worker-0", "worker-1"]
}

variable worker_name_flavor_map_sc {
  description = "Map of instance name to openstack flavor."
  type        = map

  default = {
    "worker-0" : "f6a5e4d3-203d-45c0-a36a-dc5538580e1a",
    "worker-1" : "ecd976c3-c71c-4096-b138-e4d964c0b27f"
  }
}

variable worker_names_wc {
  description = "List of names for worker instances to create."
  type        = list(string)

  default = ["worker-0", "worker-1"]
}

variable worker_name_flavor_map_wc {
  description = "Map of instance name to openstack flavor."
  type        = map

  default = {
    "worker-0" : "ecd976c3-c71c-4096-b138-e4d964c0b27f",
    "worker-1" : "ecd976c3-c71c-4096-b138-e4d964c0b27f"
  }
}

# For masters
variable master_names_sc {
  description = "List of names for master instances to create."
  type        = list(string)
  default     = ["master-0"]
}

variable master_name_flavor_map_sc {
  description = "Map of instance name to openstack flavor."
  type        = map
  default = {
    "master-0" : "89afeed0-9e41-4091-af73-727298a5d959"
  }
}

variable master_names_wc {
  description = "List of names for master instances to create."
  type        = list(string)
  default     = ["master-0"]
}

variable master_name_flavor_map_wc {
  description = "Map of instance name to openstack flavor."
  type        = map
  default = {
    "master-0" : "89afeed0-9e41-4091-af73-727298a5d959"
  }
}

# Worker instances that should have an extra volume mounted.
variable worker_extra_volume_sc {
  description = "List of worker instance names that should mount an extra volume"
  type        = list(string)
  default     = []
}

variable worker_extra_volume_wc {
  description = "List of worker instance names that should mount an extra volume"
  type        = list(string)
  default     = []
}

variable worker_extra_volume_size_sc {
  description = "Mapping from instance name to volume size for the extra volume."
  type        = map
  default     = {}
}

variable worker_extra_volume_size_wc {
  description = "Mapping from instance name to volume size for the extra volume."
  type        = map
  default     = {}
}
