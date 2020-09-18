provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  assume_role {
    role_arn = var.aws_dns_role_arn
  }
}

data "aws_route53_zone" "zone" {
  zone_id = var.aws_dns_zone_id
}

resource "aws_route53_record" "dns" {
  for_each = toset(var.dns_list)
  zone_id  = var.aws_dns_zone_id
  name     = "${each.value}.${var.dns_prefix}.${data.aws_route53_zone.zone.name}"
  type     = "A"
  ttl      = "300"
  records  = var.record_ips
}
