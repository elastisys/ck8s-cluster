# Ip address instance mapping. Contains both floating and fixed ips.
output "master_ips" {
  value = module.master.instance_ips
}

output "worker_ips" {
  value = module.worker.instance_ips
}

output "loadbalancer_ips" {
  value = module.haproxy_lb.instance_ips
}
