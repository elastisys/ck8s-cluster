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

variable public_v4_network {
  description = "the id of the public-v4 network"
  default     = "71b10496-2617-47ae-abbc-36239f0863bb"
}


# For workers
variable "worker_name_flavor_map_sc" {
  description = "Map of instance name to openstack flavor."
  type        = map
}

variable "worker_names_sc" {
  description = "List of names for worker instances to create." 
  type        = list(string)
}

variable "worker_name_flavor_map_wc" {
  description = "Map of instance name to openstack flavor."
  type        = map
}

variable "worker_names_wc" {
  type = list(string)
}


# For masters
variable "master_name_flavor_map_sc" {
  description = "Map of instance name to openstack flavor."
  type        = map
}

variable "master_names_sc" {
  description = "List of names for master instances to create."
  type = list(string)
}

variable "master_name_flavor_map_wc" {
  description = "Map of instance name to openstack flavor."
  type        = map
}

variable "master_names_wc" {
  description = "List of names for master instances to create."
  type        = list(string)
}


# Worker instances that should have an extra volume mounted.
variable "worker_extra_volume_sc" {
  description = "List of worker instance names that should mount an extra volume"
  type        = list(string)
  default     = []
}

variable "worker_extra_volume_wc" {
  description = "List of worker instance names that should mount an extra volume"
  type        = list(string)
  default     = []
}

variable "worker_extra_volume_size_sc" {
  description = "Mapping from instance name to volume size for the extra volume." 
  type        = map
  default     = {}  
}

variable "worker_extra_volume_size_wc" {
  description = "Mapping from instance name to volume size for the extra volume."
  type        = map
  default     = {}  
}
