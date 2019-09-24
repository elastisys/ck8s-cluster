variable "prefix" {}
variable "master_count" {
  type = number
}
variable "worker_count" {
  type = number
}
variable "image_id" {}
variable "key_pair" {}

variable "master_flavor_id" {}
variable "worker_flavor_id" {}
variable "nfs_flavor_id" {}

## DNS

variable "dns_name" {}

variable "aws_dns_zone_id" {
  default = "Z2STJRQSJO5PZ0" # elastisys.com
}

variable "role_arn" {
  default = "arn:aws:iam::248119176842:role/a1-pipeline"
}
