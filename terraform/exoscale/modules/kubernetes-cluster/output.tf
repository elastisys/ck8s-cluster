output "master_ip_addresses" {
  value = {
    for key, instance in exoscale_compute.master :
    instance.name => {
      "public_ip" = exoscale_compute.master[key].ip_address
    }
  }
}

output "worker_ip_addresses" {
  value = {
    for key, instance in exoscale_compute.worker :
    instance.name => {
      "public_ip" = exoscale_compute.worker[key].ip_address
    }
  }
}

output "nfs_ip_address" {
  value = "${exoscale_compute.nfs.ip_address}"
}

output "dns_record_name" {
  value = [
    for dns_record in exoscale_domain_record.ingress :
    dns_record.hostname
  ]
}

output "dns_suffix" {
  value = "${var.dns_suffix}"
}

output "ingress_controller_lb_ip_address" {
  value = "${exoscale_ipaddress.ingress_controller_lb.ip_address}"
}

output "control_plane_lb_ip_address" {
  value = "${exoscale_ipaddress.control_plane_lb.ip_address}"
}
