output "c_master_ip_address" {
  value = "${module.kubernetes_cluster.master_ip_address}"
}

#output "c_master_internal_ip_address" {
#  value = "${module.kubernetes_cluster.master_internal_ip_address}"
#}

output "c_worker_ip_addresses" {
  value = "${module.kubernetes_cluster.worker_ip_addresses}"
}

#output "c_worker_internal_ip_addresses" {
#  value = "${module.kubernetes_cluster.worker_internal_ip_addresses}"
#}

output "c_nfs_ip_address" {
  value = "${module.kubernetes_cluster.nfs_ip_address}"
}

#output "c_nfs_internal_ip_address" {
#  value = "${module.kubernetes_cluster.nfs_internal_ip_address}"
#}

#output "c_elastic_ip" {
#  value = "${module.kubernetes_cluster.elastic_ip_address}"
#}
