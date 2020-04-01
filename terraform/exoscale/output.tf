# Service cluster outputs
output "sc_master_ips" {
  value = "${module.service_cluster.master_ip_addresses}"
}

output "sc_worker_ips" {
  value = "${module.service_cluster.worker_ip_addresses}"
}

output "sc_nfs_ips" {
  value = "${module.service_cluster.nfs_ip_address}"
}

output "sc_dns_name" {
  value = "${module.service_cluster.dns_record_name}"
}

output "sc_ingress_controller_lb_ip_address" {
  value = "${module.service_cluster.ingress_controller_lb_ip_address}"
}


# Workload cluster cluster outputs

output "wc_master_ips" {
  value = "${module.workload_cluster.master_ip_addresses}"
}

output "wc_worker_ips" {
  value = "${module.workload_cluster.worker_ip_addresses}"
}

output "wc_nfs_ips" {
  value = "${module.workload_cluster.nfs_ip_address}"
}

output "wc_dns_name" {
  value = "${module.workload_cluster.dns_record_name}"
}

output "domain_name" {
  value = "${var.dns_prefix}.${module.service_cluster.dns_suffix}"
}

output "wc_ingress_controller_lb_ip_address" {
  value = "${module.workload_cluster.ingress_controller_lb_ip_address}"
}


# Unused variables for elastic-ip and internal ips.

#output "ss_worker_internal_ip_addresses" {
#  value = "${module.ss_cluster.worker_internal_ip_addresses}"
#}

#output "ss_nfs_internal_ip_address" {
#  value = "${module.ss_cluster.nfs_internal_ip_address}"
#}

#output "c_master_internal_ip_address" {
#  value = "${module.c_cluster.master_internal_ip_address}"
#}

#output "c_worker_internal_ip_addresses" {
#  value = "${module.c_cluster.worker_internal_ip_addresses}"
#}

#output "c_nfs_internal_ip_address" {
#  value = "${module.c_cluster.nfs_internal_ip_address}"
#}

#output "ss_master_internal_ip_address" {
#  value = "${module.ss_cluster.master_internal_ip_address}"
#}
