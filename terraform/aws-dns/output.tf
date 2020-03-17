output "dns_record_name" {
  value = {
    dns_sc = [for dns in aws_route53_record.dns_sc : dns.name]
    dns_wc = [for dns in aws_route53_record.dns_wc : dns.name]
  }
}

output "dns_suffix" {
  value = trimsuffix(data.aws_route53_zone.zone.name, ".")
}
