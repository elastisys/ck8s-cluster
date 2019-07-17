output "master_ip_address" {
  value = "${exoscale_compute.master.ip_address}"
}

output "worker1_ip_address" {
  value = "${exoscale_compute.worker1.ip_address}"
}

output "worker2_ip_address" {
  value = "${exoscale_compute.worker2.ip_address}"
}

output "elastic_ip_address" {
  value = "${exoscale_ipaddress.e-ip.ip_address}"
}
