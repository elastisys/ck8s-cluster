# DNS names.
output "sc_dns_name" {
  value = module.service_cluster.dns_record_name
}

# The ips by each instance name
output "sc_worker_ips" {
  value = module.service_cluster.worker_ips
}
output "sc_master_ips" {
  value = module.service_cluster.master_ips
}

output "wc_worker_ips" {
  value = module.workload_cluster.worker_ips
}
output "wc_master_ips" {
  value = module.workload_cluster.master_ips
}

output "wc_dns_name" {
  value = module.workload_cluster.dns_record_name
}

output "domain_name" {
  value = "${var.dns_prefix}.${module.service_cluster.dns_suffix}"
}


# The device paths for each instance.
output "sc_worker_device_paths" {
  value = module.service_cluster.worker_device_path
}
output "wc_worker_device_paths" {
  value = module.workload_cluster.worker_device_path
}
