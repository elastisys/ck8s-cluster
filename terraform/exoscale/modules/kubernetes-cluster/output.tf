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

output "ansible_inventory" {
  value = templatefile("${path.module}/templates/inventory.tmpl", {
    master_hosts = <<-EOF
%{for index, master in exoscale_compute.master~}
${var.prefix}-${index} ansible_host=${master.ip_address} private_ip=${master.ip_address}
%{endfor~}
EOF
    masters      = <<-EOF
%{for index, master in exoscale_compute.master~}
${var.prefix}-${index}
%{endfor~}
EOF
    worker_hosts = <<-EOF
%{for index, worker in exoscale_compute.worker~}
${var.prefix}-${index} ansible_host=${worker.ip_address} private_ip=${worker.ip_address}
%{endfor~}
EOF
    workers      = <<-EOF
%{for index, worker in exoscale_compute.worker~}
${var.prefix}-${index}
%{endfor~}
EOF
    cluster_name = var.prefix
    k8s_version  = var.k8s_version
  })
}

#  value = "${exoscale_nic.master_internal.ip_address}"
#output "master_internal_ip_address" {
#}

#output "worker_internal_ip_addresses" {
#  value = "${exoscale_nic.worker_internal.*.ip_address}"
#}

#output "nfs_internal_ip_address" {
#  value = "${exoscale_nic.nfs_internal.ip_address}"
#}

output "ingress_controller_lb_ip_address" {
  value = "${exoscale_ipaddress.ingress_controller_lb.ip_address}"
}
