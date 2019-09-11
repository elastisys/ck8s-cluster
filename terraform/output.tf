# System services cluster outputs

output "system_services_worker_count" {
  value = "${var.system_services_worker_count}"
}

output "system_services_master_ip_address" {
  value = "${module.system_services_cluster.master_ip_address}"
}

#output "ss_master_internal_ip_address" {
#  value = "${module.ss_cluster.master_internal_ip_address}"
#}

output "system_services_worker_ip_addresses" {
  value = "${module.system_services_cluster.worker_ip_addresses}"
}

#output "ss_worker_internal_ip_addresses" {
#  value = "${module.ss_cluster.worker_internal_ip_addresses}"
#}

output "system_services_nfs_ip_address" {
  value = "${module.system_services_cluster.nfs_ip_address}"
}

#output "ss_nfs_internal_ip_address" {
#  value = "${module.ss_cluster.nfs_internal_ip_address}"
#}

#output "ss_elastic_ip" {
#  value = "${module.ss_cluster.elastic_ip_address}"
#}

output "system_services_dns_name"{
  value = "${module.system_services_cluster.dns_record_name}"
}


#Customer cluster outputs

output "customer_worker_count" {
  value = "${var.customer_worker_count}"
}

# TODO - add master count

output "customer_master_ip_address" {
  value = "${module.customer_cluster.master_ip_address}"
}

#output "c_master_internal_ip_address" {
#  value = "${module.c_cluster.master_internal_ip_address}"
#}

output "customer_worker_ip_addresses" {
  value = "${module.customer_cluster.worker_ip_addresses}"
}

#output "c_worker_internal_ip_addresses" {
#  value = "${module.c_cluster.worker_internal_ip_addresses}"
#}

output "customer_nfs_ip_address" {
  value = "${module.customer_cluster.nfs_ip_address}"
}

#output "c_nfs_internal_ip_address" {
#  value = "${module.c_cluster.nfs_internal_ip_address}"
#}

#output "c_elastic_ip" {
#  value = "${module.c_cluster.elastic_ip_address}"
#}

output "customer_dns_name"{
  value = "${module.customer_cluster.dns_record_name}"
}
