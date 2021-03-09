output "sc_master_ips" {
  value = module.kubernetes.master_ips
}

output "sc_worker_ips" {
  value = module.kubernetes.worker_ips
}

output "sc_master_external_loadbalancer_fqdn" {
  value = module.kubernetes.master_external_loadbalancer_fqdn
}

output "sc_master_internal_loadbalancer_fqdn" {
  value = module.kubernetes.master_internal_loadbalancer_fqdn
}
