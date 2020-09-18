# DNS names.
output "sc_dns_name" {
  value = module.service_cluster.dns_record_name
}
output "wc_dns_name" {
  value = module.workload_cluster.dns_record_name
}
output "domain_name" {
  value = "${var.dns_prefix}.${module.service_cluster.dns_suffix}"
}

# The ips by each instance name
output "sc_worker_ips" {
  value = module.service_cluster.worker_ips
}

output "sc_control_plane_endpoint" {
  value = length(values(module.service_cluster.loadbalancer_ips)) > 0 ? values(module.service_cluster.loadbalancer_ips)[0].private_ip : ""
}
output "sc_master_ips" {
  value = module.service_cluster.master_ips
}
output "sc_loadbalancer_ips" {
  value = module.service_cluster.loadbalancer_ips
}

output "sc_ingress_controller_lb_ip_address" {
  value = length(values(module.service_cluster.loadbalancer_ips)) > 0 ? values(module.service_cluster.loadbalancer_ips)[0].public_ip : ""
}

output "sc_control_plane_lb_ip_address" {
  value = length(values(module.service_cluster.loadbalancer_ips)) > 0 ? values(module.service_cluster.loadbalancer_ips)[0].public_ip : ""
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
