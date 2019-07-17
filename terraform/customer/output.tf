output "c-master-ip" {
  value = "${module.kubernetes_cluster.master_ip_address}"
}

output "c-worker1-ip" {
  value = "${module.kubernetes_cluster.worker1_ip_address}"
}

output "c-worker2-ip" {
  value = "${module.kubernetes_cluster.worker2_ip_address}"
}

output "c-elastic-ip" {
  value = "${module.kubernetes_cluster.elastic_ip_address}"
}
