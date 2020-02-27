output "sc_master_public_ips" {
  value = module.service_cluster.master_public_ips
}

output "wc_master_public_ips" {
  value = module.workload_cluster.master_public_ips
}

output "sc_worker_public_ips" {
  value = module.service_cluster.worker_public_ips
}

output "wc_worker_public_ips" {
  value = module.workload_cluster.worker_public_ips
}

output "sc_master_external_loadbalancer_fqdn" {
  value = module.service_cluster.master_external_loadbalancer_fqdn
}

output "wc_master_external_loadbalancer_fqdn" {
  value = module.workload_cluster.master_external_loadbalancer_fqdn
}
