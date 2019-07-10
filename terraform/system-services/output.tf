output "ss-master-ip" {
  value = "${exoscale_compute.ss-master.ip_address}"
}
output "ss-worker1-ip" {
  value = "${exoscale_compute.ss-worker1.ip_address}"
}
output "ss-worker2-ip" {
  value = "${exoscale_compute.ss-worker2.ip_address}"
}

output "ss-elastic-ip" {
  value = "${exoscale_ipaddress.ss-e-ip.ip_address}"
}