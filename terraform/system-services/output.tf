output "ss-master-ip" {
  value = "${module.kubernetes_cluster.master_ip_address}"
}

output "ss-worker1-ip" {
  value = "${module.kubernetes_cluster.worker1_ip_address}"
}

output "ss-worker2-ip" {
  value = "${module.kubernetes_cluster.worker2_ip_address}"
}

output "ss-elastic-ip" {
  value = "${module.kubernetes_cluster.elastic_ip_address}"
}
