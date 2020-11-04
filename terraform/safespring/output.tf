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

output "wc_ingress_controller_lb_ip_address" {
  value = length(values(module.workload_cluster.loadbalancer_ips)) > 0 ? values(module.workload_cluster.loadbalancer_ips)[0].public_ip : ""
}

output "wc_control_plane_lb_ip_address" {
  value = length(values(module.workload_cluster.loadbalancer_ips)) > 0 ? values(module.workload_cluster.loadbalancer_ips)[0].public_ip : ""
}
