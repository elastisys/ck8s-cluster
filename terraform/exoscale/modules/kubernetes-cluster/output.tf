output "master_ip_addresses" {
  value = {
    for key, instance in exoscale_compute.master:
    instance.name => {
      "public_ip" = exoscale_compute.master[key].ip_address
    }
  }
}

output "worker_ip_addresses" {
  value = {
    for key, instance in exoscale_compute.worker:
    instance.name => {
      "public_ip" = exoscale_compute.worker[key].ip_address
    }
  }
}

output "nfs_ip_address" {
  value = "${exoscale_compute.nfs.ip_address}"
}

output "dns_record_name" {
  value = exoscale_domain_record.worker[*].hostname
}

output "dns_suffix" {
  value = "${var.dns_suffix}"
}
#  value = "${exoscale_nic.master_internal.ip_address}"
#output "master_internal_ip_address" {
#}

#output "worker_internal_ip_addresses" {
#  value = "${exoscale_nic.worker_internal.*.ip_address}"
#}

#output "nfs_internal_ip_address" {
#  value = "${exoscale_nic.nfs_internal.ip_address}"
#}

#output "elastic_ip_address" {
#  value = "${exoscale_ipaddress.eip.ip_address}"
#}
