provider "aws" {
  version                 = "~> 2.50"
  region                  = var.region
  shared_credentials_file = pathexpand(var.credentials_file_path)
  assume_role {
    role_arn = var.role_arn
  }
}

data "aws_route53_zone" "zone" {
  zone_id = var.aws_dns_zone_id
}

resource "aws_route53_record" "dns" {
  for_each = toset(var.dns_list)
  zone_id  = var.aws_dns_zone_id
  name     = "${each.value}.${data.aws_route53_zone.zone.name}"
  type     = "A"
  ttl      = "300"
  records  = var.dns_records
}
