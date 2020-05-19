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
  default     = ["worker-0", "worker-1"]
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

variable public_ingress_cidr_whitelist {
  type = string
}

variable external_network_id {
  description = "the id of the external network"
  type        = string
  default     = "2aec7a99-3783-4e2a-bd2b-bbe4fef97d1c"
}

variable external_network_name {
  description = "the name of the external network"
  type        = string
  default     = "ext-net"
}
