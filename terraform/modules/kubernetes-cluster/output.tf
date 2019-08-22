output "master_ip_address" {
  value = "${exoscale_compute.master.ip_address}"
}

#output "master_internal_ip_address" {
#  value = "${exoscale_nic.master_internal.ip_address}"
#}

output "worker_ip_addresses" {
  value = "${exoscale_compute.worker.*.ip_address}"
}

#output "worker_internal_ip_addresses" {
#  value = "${exoscale_nic.worker_internal.*.ip_address}"
#}

output "nfs_ip_address" {
  value = "${exoscale_compute.nfs.ip_address}"
}

#output "nfs_internal_ip_address" {
#  value = "${exoscale_nic.nfs_internal.ip_address}"
#}

#output "elastic_ip_address" {
#  value = "${exoscale_ipaddress.eip.ip_address}"
#}

output "dns_record_name" {
  value = "${aws_route53_record.dns.name}"
}
