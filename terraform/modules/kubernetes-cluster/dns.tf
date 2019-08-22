provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::248119176842:role/a1-pipeline"
  }
}

data "aws_route53_zone" "zone" {
  zone_id = "${var.aws_dns_zone_id}"
}

resource "aws_route53_record" "dns" {
  zone_id = "${var.aws_dns_zone_id}"
  name    = "*.${var.dns_name}.${data.aws_route53_zone.zone.name}"
  type    = "A"
  ttl     = "300"
  # TODO change records to eip once working
  records = "${exoscale_compute.worker.*.ip_address}"
}
