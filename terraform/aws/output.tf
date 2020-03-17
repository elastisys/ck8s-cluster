output "sc_master_ips" {
  value = module.service_cluster.master_ips
}

output "wc_master_ips" {
  value = module.workload_cluster.master_ips
}

output "sc_worker_ips" {
  value = module.service_cluster.worker_ips
}

output "wc_worker_ips" {
  value = module.workload_cluster.worker_ips
}

output "sc_master_external_loadbalancer_fqdn" {
  value = module.service_cluster.master_external_loadbalancer_fqdn
}

output "sc_master_internal_loadbalancer_fqdn" {
  value = module.service_cluster.master_internal_loadbalancer_fqdn
}

output "wc_master_external_loadbalancer_fqdn" {
  value = module.workload_cluster.master_external_loadbalancer_fqdn
}

output "wc_master_internal_loadbalancer_fqdn" {
  value = module.workload_cluster.master_internal_loadbalancer_fqdn
}

output "ansible_inventory_sc" {
  value = module.service_cluster.ansible_inventory
}

output "ansible_inventory_wc" {
  value = module.workload_cluster.ansible_inventory
}
