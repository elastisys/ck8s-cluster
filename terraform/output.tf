output "master-ip" {
  value = "${exoscale_compute.master.ip_address}"
}
output "worker1-ip" {
  value = "${exoscale_compute.worker1.ip_address}"
}
output "worker2-ip" {
  value = "${exoscale_compute.worker2.ip_address}"
}
