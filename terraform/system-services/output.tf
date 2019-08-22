output "ss_master_ip_address" {
  value = "${module.kubernetes_cluster.master_ip_address}"
}

#output "ss_master_internal_ip_address" {
#  value = "${module.kubernetes_cluster.master_internal_ip_address}"
#}

output "ss_worker_ip_addresses" {
  value = "${module.kubernetes_cluster.worker_ip_addresses}"
}

#output "ss_worker_internal_ip_addresses" {
#  value = "${module.kubernetes_cluster.worker_internal_ip_addresses}"
#}

output "ss_nfs_ip_address" {
  value = "${module.kubernetes_cluster.nfs_ip_address}"
}

#output "ss_nfs_internal_ip_address" {
#  value = "${module.kubernetes_cluster.nfs_internal_ip_address}"
#}

#output "ss_elastic_ip" {
#  value = "${module.kubernetes_cluster.elastic_ip_address}"
#}

output "ss_dns_name"{
  value = "${module.kubernetes_cluster.dns_record_name}"
}
