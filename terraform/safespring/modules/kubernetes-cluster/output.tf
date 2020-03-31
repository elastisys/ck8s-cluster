output "dns_record_name" {
  value = [
    for dns in aws_route53_record.dns : dns.name
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

output "loadbalancer_ips" {
  value = module.loadbalancer.instance_ips
}

# For device paths
output "worker_device_path" {
  value = {
    for instance in var.worker_extra_volume :
    instance => openstack_compute_volume_attach_v2.worker_va[instance].device
  }
}

output "ansible_inventory" {
  value = templatefile("${path.module}/templates/inventory.tmpl", {
    master_hosts   = <<-EOF
%{for key, master in module.master.instance_ips~}
${key} ansible_host=${master.public_ip} private_ip=${master.private_ip}
%{endfor~}
EOF
    masters        = <<-EOF
%{for key, master in module.master.instance_ips~}
${key}
%{endfor~}
EOF
    worker_hosts   = <<-EOF
%{for key, worker in module.worker.instance_ips~}
${key} ansible_host=${worker.public_ip} private_ip=${worker.private_ip}
%{endfor~}
EOF
    workers        = <<-EOF
%{for key, worker in module.worker.instance_ips~}
${key}
%{endfor~}
EOF
    extra_volume   = <<-EOF
%{for key, worker in var.worker_extra_volume~}
${key} device_path=${openstack_compute_volume_attach_v2.worker_va[worker].device}
%{endfor~}
EOF
    cluster_name = var.prefix
    k8s_version  = var.k8s_version
  })
}
