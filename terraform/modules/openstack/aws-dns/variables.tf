variable "dns_list" {
  type = list(string)
}

variable "dns_prefix" {}

variable "aws_dns_zone_id" {}

variable "aws_dns_role_arn" {}

variable "record_ips" {}
