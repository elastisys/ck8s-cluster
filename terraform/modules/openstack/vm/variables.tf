variable "key_pair" {}
variable "network_id" {}
variable "subnet_id" {}
variable "prefix" {}

variable "security_group_ids" {
  type = list(string)
}

variable machines {
  type = map(object({
    size  = string
    image = string
  }))
}

variable external_network_name {
  description = "the name of the external network"
  type        = string
}

variable "server_group_id" {
  description = "Id to the servergroup these instances should belong to."
  type        = string
}
