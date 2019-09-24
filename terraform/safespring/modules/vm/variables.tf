variable "instance_name" {}
variable "instance_count" {
  type    = number
  default = 1
}
variable "image_id" {}
variable "flavor_id" {}
variable "key_pair" {}
variable "network_id" {}
variable "subnet_id" {}
variable "security_group_ids" {
  type = list
}
