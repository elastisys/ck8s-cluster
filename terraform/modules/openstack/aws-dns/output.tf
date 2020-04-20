output "dns_record_name" {
  value = [
    for dns in aws_route53_record.dns : dns.name
  ]
}

output "dns_suffix" {
  value = trimsuffix(data.aws_route53_zone.zone.name, ".")
}