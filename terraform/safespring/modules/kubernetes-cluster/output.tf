output "master_floating_ip" {
  value = module.master.floating_ips
}

output "master_fixed_ip" {
  value = module.master.fixed_ips
}

output "worker_floating_ips" {
  value = module.worker.floating_ips
}

output "worker_fixed_ips" {
  value = module.worker.fixed_ips
}

output "nfs_floating_ip" {
  value = module.nfs.floating_ips[0]
}

output "nfs_fixed_ip" {
  value = module.nfs.fixed_ips[0]
}

output "nfs_device_path" {
  value = openstack_compute_volume_attach_v2.nfs_va.device
}

#output "dns_record_name" {
#  value = aws_route53_record.dns.names
#}