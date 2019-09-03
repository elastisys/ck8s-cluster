# System services cluster outputs

output "ss_worker_count" {
  value = "${var.ss_worker_count}"
}

output "ss_master_ip_address" {
  value = "${module.ss_cluster.master_ip_address}"
}

#output "ss_master_internal_ip_address" {
#  value = "${module.ss_cluster.master_internal_ip_address}"
#}

output "ss_worker_ip_addresses" {
  value = "${module.ss_cluster.worker_ip_addresses}"
}

#output "ss_worker_internal_ip_addresses" {
#  value = "${module.ss_cluster.worker_internal_ip_addresses}"
#}

output "ss_nfs_ip_address" {
  value = "${module.ss_cluster.nfs_ip_address}"
}

#output "ss_nfs_internal_ip_address" {
#  value = "${module.ss_cluster.nfs_internal_ip_address}"
#}

#output "ss_elastic_ip" {
#  value = "${module.ss_cluster.elastic_ip_address}"
#}

output "ss_dns_name"{
  value = "${module.ss_cluster.dns_record_name}"
}


#Customer cluster outputs

output "c_worker_count" {
  value = "${var.c_worker_count}"
}

# TODO - add master count

output "c_master_ip_address" {
  value = "${module.c_cluster.master_ip_address}"
}

#output "c_master_internal_ip_address" {
#  value = "${module.c_cluster.master_internal_ip_address}"
#}

output "c_worker_ip_addresses" {
  value = "${module.c_cluster.worker_ip_addresses}"
}

#output "c_worker_internal_ip_addresses" {
#  value = "${module.c_cluster.worker_internal_ip_addresses}"
#}

output "c_nfs_ip_address" {
  value = "${module.c_cluster.nfs_ip_address}"
}

#output "c_nfs_internal_ip_address" {
#  value = "${module.c_cluster.nfs_internal_ip_address}"
#}

#output "c_elastic_ip" {
#  value = "${module.c_cluster.elastic_ip_address}"
#}

output "c_dns_name"{
  value = "${module.c_cluster.dns_record_name}"
}
