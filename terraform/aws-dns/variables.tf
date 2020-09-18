variable "region" {
  default = "us-east-1"
}

variable dns_access_key {
  description = "AWS API access key for DNS"
  type        = string
}

variable dns_secret_key {
  description = "AWS API secret key for DNS"
  type        = string
}

variable dns_prefix {
  type = string
}

variable "sub_domains_sc" {
  type        = list(string)
  description = "The sub domain names that should point to the service cluster loadbalancer. These will be combined with the dns_prefix to form the FQDN, like this: sub_domain.dns_prefix."
  default = [
    "*.ops",
    "grafana",
    "harbor",
    "dex",
    "kibana",
    "notary.harbor"
  ]
}

variable "sub_domains_wc" {
  type        = list(string)
  description = "The sub domain names that should point to the workload cluster loadbalancer. These will be combined with the dns_prefix to form the FQDN, like this: sub_domain.dns_prefix."
  default = [
    "*",
    "prometheus.ops"
  ]
}

variable "aws_dns_zone_id" {}

variable "role_arn" {}

variable "dns_record_sc" {
  type        = string
  description = "The FQDN of the service cluster loadbalancer."
}

variable "dns_record_wc" {
  type        = string
  description = "The FQDN of the workload cluster loadbalancer."
}
