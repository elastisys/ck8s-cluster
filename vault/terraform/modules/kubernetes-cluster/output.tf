output "master_ip_addresses" {
  value = "${exoscale_compute.master.*.ip_address}"
}

output "nfs_ip_address" {
  value = "${exoscale_compute.nfs.ip_address}"
}

output "dns_record_name" {
  value = "${aws_route53_record.dns.name}"
}
