variable "region" {
  default = "us-east-1"
}

variable "credentials_file_path" {
  description = "Path to credentials file, passed to pathexpand"
}

variable "dns_list" {
  type = list(string)
}

variable "aws_dns_zone_id" {
  default = "Z2STJRQSJO5PZ0" # elastisys.se
}

variable "role_arn" {
  default = "arn:aws:iam::248119176842:role/a1-pipeline"
}

variable "dns_records" {
  type = list(string)
}
