provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "aws_route53_zone" "zone" {
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "dns" {
  zone_id = "${var.zone_id}"
  name    = "*.${var.dns_name}.${data.aws_route53_zone.zone.name}"
  type    = "A"
  ttl     = "300"
  records = "${exoscale_compute.worker.*.ip_address}"
}
