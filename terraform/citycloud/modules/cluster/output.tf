# Ip address instance mapping. Contains both floating and fixed ips.
output "master_ips" {
  value = module.master.instance_ips
}

output "worker_ips" {
  value = module.worker.instance_ips
}

output "loadbalancer_ips" {
  value = module.octavia_lb.instance_ips
}

output subnet_id {
  value = module.network.subnet_id
}

output cluster_secgroup_id {
  value = module.secgroups.cluster_secgroup
}
