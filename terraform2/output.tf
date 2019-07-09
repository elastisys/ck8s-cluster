output "storagemaster-ip" {
  value = "${exoscale_compute.storagemaster.ip_address}"
}
output "storageworker1-ip" {
  value = "${exoscale_compute.storageworker1.ip_address}"
}
output "storageworker2-ip" {
  value = "${exoscale_compute.storageworker2.ip_address}"
}

output "elastic-ip" {
  value = "${exoscale_ipaddress.e_ip.ip_address}"
}