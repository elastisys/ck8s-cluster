output "dns_record_name" {
  value = [ 
    for dns in aws_route53_record.dns: dns.name
  ]
}

output "dns_suffix" {
  value = trimsuffix(data.aws_route53_zone.zone.name, ".")
}

# List of worker floating ips. Used for creating dns records!
output "worker_floating_ips" {
  value = module.worker.floating_ips
}

# Ip address instance mapping. Contains both floating and fixed ips.
output "master_ips" {
  value = module.master.instance_ips
}

output "worker_ips" {
  value = module.worker.instance_ips
}

output "lb_ip" {
  value = openstack_networking_floatingip_v2.loadbalancer-lb-fip.address
}

# For device paths
output "worker_device_path" {
  value = {
    for instance in var.worker_extra_volume:
    instance => openstack_compute_volume_attach_v2.worker_va[instance].device
  }
}
