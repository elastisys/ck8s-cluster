# DNS names.
output "sc_dns_name" {
  value = module.service_cluster.dns_record_name
}
output "wc_dns_name" {
  value = module.workload_cluster.dns_record_name
}
output "domain_name" {
  value = "${var.dns_prefix}.${module.service_cluster.dns_suffix}"
}

# The ips by each instance name
output "sc_worker_ips" {
  value = module.service_cluster.worker_ips
}
output "sc_master_ips" {
  value = module.service_cluster.master_ips
}
output "sc_loadbalancer_ips" {
  value = module.service_cluster.loadbalancer_ips
}

output "wc_worker_ips" {
  value = module.workload_cluster.worker_ips
}
output "wc_master_ips" {
  value = module.workload_cluster.master_ips
}
output "wc_loadbalancer_ips" {
  value = module.workload_cluster.loadbalancer_ips
}

output "ansible_inventory_sc" {
  value = templatefile("${path.module}/../templates/inventory.tmpl", {
    master_hosts           = <<-EOF
%{for key, master in module.service_cluster.master_ips~}
${key} ansible_host=${master.public_ip} private_ip=${master.private_ip}
%{endfor~}
EOF
    masters                = <<-EOF
%{for key, master in module.service_cluster.master_ips~}
${key}
%{endfor~}
EOF
    worker_hosts           = <<-EOF
%{for key, worker in module.service_cluster.worker_ips~}
${key} ansible_host=${worker.public_ip} private_ip=${worker.private_ip}
%{endfor~}
EOF
    workers                = <<-EOF
%{for key, worker in module.service_cluster.worker_ips~}
${key}
%{endfor~}
EOF
    cluster_name           = var.prefix_sc == "" ? "${terraform.workspace}-service-cluster" : var.prefix_sc
    cloud_provider         = "openstack"
    cloud_config           = "/etc/kubernetes/cloud.conf"
    calico_mtu             = "1480"
    loadbalancers          = ""
    public_endpoint        = values(module.service_cluster.master_ips)[0].public_ip
    control_plane_endpoint = ""
    control_plane_port     = ""
    internal_lb_children   = ""
  })
}

output "ansible_inventory_wc" {
  value = templatefile("${path.module}/../templates/inventory.tmpl", {
    master_hosts           = <<-EOF
%{for key, master in module.workload_cluster.master_ips~}
${key} ansible_host=${master.public_ip} private_ip=${master.private_ip}
%{endfor~}
EOF
    masters                = <<-EOF
%{for key, master in module.workload_cluster.master_ips~}
${key}
%{endfor~}
EOF
    worker_hosts           = <<-EOF
%{for key, worker in module.workload_cluster.worker_ips~}
${key} ansible_host=${worker.public_ip} private_ip=${worker.private_ip}
%{endfor~}
EOF
    workers                = <<-EOF
%{for key, worker in module.workload_cluster.worker_ips~}
${key}
%{endfor~}
EOF
    cluster_name           = var.prefix_wc == "" ? "${terraform.workspace}-workload-cluster" : var.prefix_wc
    cloud_provider         = "openstack"
    cloud_config           = "/etc/kubernetes/cloud.conf"
    calico_mtu             = "1480"
    loadbalancers          = ""
    public_endpoint        = values(module.workload_cluster.master_ips)[0].public_ip
    control_plane_endpoint = ""
    control_plane_port     = ""
    internal_lb_children   = ""
  })
}
