## Global ##

variable prefix {
  default = ""
}

variable "network" {
  type = map
  
  default = {
    service_cluster = "VM Network"
  }
}

variable "ip_prefix" {
  default = "51.89.210"
}

variable "ip_last_octet_start_number_master" {
  default = "153"
}

variable "ip_last_octet_start_number_worker" {
  default = "154"
}

variable "gateway" {
  default = "51.89.210.158"
}

variable "dns_primary" {
  default = "8.8.4.4"
}

variable "dns_secondary" {
  default = "8.8.8.8"
}

variable "vsphere_datacenter" {
  default = "pcc-145-239-249-136_datacenter869"
}

variable "vsphere_compute_cluster" {
  default = "Cluster1"
}

variable "vsphere_datastore" {
  default= "ssd-000850"
}

variable "vsphere_server" {
  default = "pcc-145-239-249-136.ovh.uk"
}

variable "vsphere_hostname" {
  default = "172.16.254.50"
}

variable "firmware" {
  default = "bios"
}

variable "hardware_version" {
  default = "15"
}

variable "template_name" {
  default = "ubuntu-bionic-18.04-cloudimg-20201125"
}

variable "prefix_sc" {
  default = ""
}

variable "prefix_wc" {
  default = ""
}

variable "ssh_pub_key" {
  default = ""
}

## Master ##
variable "master_count" {
  default = "1"
}
variable "master_cores" {
  default = 4
}

variable "master_memory" {
  default = 8192
}

variable "master_disk_size" {
  default = "20"
}

## Worker ##

variable "worker_count" {
  default = "1"
}
variable "worker_cores" {
  default = 16
}

variable "worker_memory" {
  default = 24576
}
variable "worker_disk_size" {
  default = "100"
}
