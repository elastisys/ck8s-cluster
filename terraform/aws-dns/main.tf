provider "aws" {
  version    = "~> 2.50"
  region     = var.region
  access_key = var.dns_access_key
  secret_key = var.dns_secret_key
  assume_role {
    role_arn = var.role_arn
  }
}

data "aws_route53_zone" "zone" {
  zone_id = var.aws_dns_zone_id
}

resource "aws_route53_record" "dns_sc" {
  for_each = toset(var.sub_domains_sc)
  zone_id  = var.aws_dns_zone_id
  name     = "${each.value}.${var.dns_prefix}.${data.aws_route53_zone.zone.name}"
  type     = "CNAME"
  ttl      = "300"
  records  = [var.dns_record_sc]
}

resource "aws_route53_record" "dns_wc" {
  for_each = toset(var.sub_domains_wc)
  zone_id  = var.aws_dns_zone_id
  name     = "${each.value}.${var.dns_prefix}.${data.aws_route53_zone.zone.name}"
  type     = "CNAME"
  ttl      = "300"
  records  = [var.dns_record_wc]
}
