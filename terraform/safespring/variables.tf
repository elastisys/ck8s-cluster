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

variable public_v4_network {
  description = "the id of the public-v4 network"
  default     = "71b10496-2617-47ae-abbc-36239f0863bb"
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
  description = "Base image used to provision master and worker instances"
  default     = "CK8S-BaseOS-v0.0.4"
}

# For workers
# Common flavors
# b.small  : 1493be98-d150-4f69-8154-4d59ea49681c
# b.medium : 9d82d1ee-ca29-4928-a868-d56e224b92a1
# b.large  : 16d11558-62fe-4bce-b8de-f49a077dc881
# m.medium : 2c1708d1-3974-4ab8-97cc-cbf58aa27ad9
# b.xlarge : fce2b54d-c0ef-4ad4-aa81-bcdcaa54f7cb
# AMD flavors, preferred!
# lb.tiny     : 51d480b8-2517-4ba8-bfe0-c649ac93eb61
# lb.large.1d : dc67a9eb-0685-4bb6-9383-a01c717e02e8
variable worker_names_sc {
  description = "List of names for worker instances to create."
  type        = list(string)

  default = ["worker-0", "worker-1"]
}

variable worker_name_flavor_map_sc {
  description = "Map of instance name to openstack flavor."
  type        = map
  default = {
    "worker-0" : "fce2b54d-c0ef-4ad4-aa81-bcdcaa54f7cb",
    "worker-1" : "16d11558-62fe-4bce-b8de-f49a077dc881"
  }
}

variable worker_names_wc {
  description = "List of names for worker instances to create."
  type        = list(string)
  default     = ["worker-0", "worker-1"]
}

variable worker_name_flavor_map_wc {
  description = "Map of instance name to openstack flavor."
  type        = map
  default = {
    "worker-0" : "16d11558-62fe-4bce-b8de-f49a077dc881",
    "worker-1" : "16d11558-62fe-4bce-b8de-f49a077dc881"
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
  default = {
    "master-0" : "9d82d1ee-ca29-4928-a868-d56e224b92a1"
  }
}

variable loadbalancer_names_sc {
  description = "List of names for loadbalancer instances to create."
  type        = list(string)
  default     = ["sc-lb-0"]
}

variable loadbalancer_name_flavor_map_sc {
  description = "Map of instance name to openstack flavor."
  type        = map
  default = {
    "sc-lb-0" : "51d480b8-2517-4ba8-bfe0-c649ac93eb61"
  }
}


variable loadbalancer_names_wc {
  description = "List of names for loadbalancer instances to create."
  type        = list(string)
  default     = ["wc-lb-0"]
}

variable loadbalancer_name_flavor_map_wc {
  description = "Map of instance name to openstack flavor."
  type        = map
  default = {
    "wc-lb-0" : "51d480b8-2517-4ba8-bfe0-c649ac93eb61"
  }
}

variable public_ingress_cidr_whitelist {
  type = string
}
