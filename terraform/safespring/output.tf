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

output "sc_loadbalancer_ips" {
  value = module.service_cluster.loadbalancer_ips
}

output "wc_worker_ips" {
  value = module.workload_cluster.worker_ips
}
output "wc_master_ips" {
  value = module.workload_cluster.master_ips
}

output "wc_loadbalancer_ips" {
  value = module.workload_cluster.loadbalancer_ips
}

output "wc_dns_name" {
  value = module.workload_cluster.dns_record_name
}

output "domain_name" {
  value = "${var.dns_prefix}.${module.service_cluster.dns_suffix}"
}

output "ansible_inventory_sc" {
  value = module.service_cluster.ansible_inventory
}

output "ansible_inventory_wc" {
  value = module.workload_cluster.ansible_inventory
}
