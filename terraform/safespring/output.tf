output "sc_master_ip_addresses" {
  value = module.service_cluster.master_floating_ip
}

output "sc_master_private_ip_addresses" {
  value = module.service_cluster.master_fixed_ip
}

output "sc_worker_ip_addresses" {
  value = module.service_cluster.worker_floating_ips
}

output "sc_worker_private_ip_addresses" {
  value = module.service_cluster.worker_fixed_ips
}

output "sc_nfs_ip_address" {
  value = module.service_cluster.nfs_floating_ip
}

output "sc_nfs_private_ip_address" {
  value = module.service_cluster.nfs_fixed_ip
}

output "sc_nfs_device_path" {
  value = module.service_cluster.nfs_device_path
}

#output "sc_dns_name" {
#  value = module.service_cluster.dns_record_name
#}

output "wc_master_ip_addresses" {
  value = module.workload_cluster.master_floating_ip
}

output "wc_master_private_ip_addresses" {
  value = module.workload_cluster.master_fixed_ip
}

output "wc_worker_ip_addresses" {
  value = module.workload_cluster.worker_floating_ips
}

output "wc_worker_private_ip_addresses" {
  value = module.workload_cluster.worker_fixed_ips
}

output "wc_nfs_ip_address" {
  value = module.workload_cluster.nfs_floating_ip
}

output "wc_nfs_private_ip_address" {
  value = module.workload_cluster.nfs_fixed_ip
}

output "wc_nfs_device_path" {
  value = module.workload_cluster.nfs_device_path
}

#output "wc_dns_name" {
#  value = module.workload_cluster.dns_record_name
#}
