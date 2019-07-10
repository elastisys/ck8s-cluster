output "c-master-ip" {
  value = "${exoscale_compute.c-master.ip_address}"
}
output "c-worker1-ip" {
  value = "${exoscale_compute.c-worker1.ip_address}"
}
output "c-worker2-ip" {
  value = "${exoscale_compute.c-worker2.ip_address}"
}

output "c-elastic-ip" {
  value = "${exoscale_ipaddress.c-e-ip.ip_address}"
}