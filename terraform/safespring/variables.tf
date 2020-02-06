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

variable public_v4_network {
  description = "the id of the public-v4 network"
  default     = "71b10496-2617-47ae-abbc-36239f0863bb"
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
# b.small  : 1493be98-d150-4f69-8154-4d59ea49681c
# b.medium : 9d82d1ee-ca29-4928-a868-d56e224b92a1
# b.large  : 16d11558-62fe-4bce-b8de-f49a077dc881
# m.medium : 2c1708d1-3974-4ab8-97cc-cbf58aa27ad9
variable worker_names_sc {
  description = "List of names for worker instances to create." 
  type        = list(string)

  default     = ["worker-0","worker-1"]
}

variable worker_name_flavor_map_sc {
  description = "Map of instance name to openstack flavor."
  type        = map

  default     = {
    "worker-0" : "16d11558-62fe-4bce-b8de-f49a077dc881",
    "worker-1" : "16d11558-62fe-4bce-b8de-f49a077dc881"  
  }
}

variable worker_names_wc {
  description = "List of names for worker instances to create." 
  type        = list(string)

  default     = ["worker-0","worker-1"]
}

variable worker_name_flavor_map_wc {
  description = "Map of instance name to openstack flavor."
  type        = map

  default     = {
    "worker-0" : "16d11558-62fe-4bce-b8de-f49a077dc881",
    "worker-1" : "16d11558-62fe-4bce-b8de-f49a077dc881"  
  }
}

# For masters
variable master_names_sc {
  description = "List of names for master instances to create."
  type = list(string)
  default     = ["master-0"]
}

variable master_name_flavor_map_sc {
  description = "Map of instance name to openstack flavor."
  type        = map
  default     = {
    "master-0" : "9d82d1ee-ca29-4928-a868-d56e224b92a1"
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
  default     = {
    "master-0" : "9d82d1ee-ca29-4928-a868-d56e224b92a1"
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

variable public_ingress_cidr_whitelist {
  type    = string
  default = "194.132.164.168/32" # Elastisys office
}