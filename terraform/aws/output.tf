output "sc_master_ips" {
  value = module.service_cluster.master_ips
}

output "wc_master_ips" {
  value = module.workload_cluster.master_ips
}

output "sc_worker_ips" {
  value = module.service_cluster.worker_ips
}

output "wc_worker_ips" {
  value = module.workload_cluster.worker_ips
}

output "sc_master_external_loadbalancer_fqdn" {
  value = module.service_cluster.master_external_loadbalancer_fqdn
}

output "sc_master_internal_loadbalancer_fqdn" {
  value = module.service_cluster.master_internal_loadbalancer_fqdn
}

output "wc_master_external_loadbalancer_fqdn" {
  value = module.workload_cluster.master_external_loadbalancer_fqdn
}

output "wc_master_internal_loadbalancer_fqdn" {
  value = module.workload_cluster.master_internal_loadbalancer_fqdn
}

output "ansible_inventory_sc" {
  value = templatefile("${path.module}/../templates/inventory.tmpl", {
    master_hosts           = <<-EOF
%{for index, master in module.service_cluster.master_ips~}
${local.prefix_sc}-${index} ansible_host=${master.public_ip} private_ip=${master.private_ip}
%{endfor~}
EOF
    masters                = <<-EOF
%{for index, master in module.service_cluster.master_ips~}
${local.prefix_sc}-${index}
%{endfor~}
EOF
    worker_hosts           = <<-EOF
%{for index, worker in module.service_cluster.worker_ips~}
${local.prefix_sc}-${index} ansible_host=${worker.public_ip} private_ip=${worker.private_ip}
%{endfor~}
EOF
    workers                = <<-EOF
%{for index, worker in module.service_cluster.worker_ips~}
${local.prefix_sc}-${index}
%{endfor~}
EOF
    control_plane_endpoint = module.service_cluster.master_internal_loadbalancer_fqdn
    public_endpoint        = module.service_cluster.master_external_loadbalancer_fqdn
    cluster_name           = local.prefix_sc
    cloud_provider         = "aws"
    cloud_config           = ""
    loadbalancers          = ""
    control_plane_port     = ""
  })
}

output "ansible_inventory_wc" {
  value = templatefile("${path.module}/../templates/inventory.tmpl", {
    master_hosts           = <<-EOF
%{for index, master in module.workload_cluster.master_ips~}
${local.prefix_wc}-${index} ansible_host=${master.public_ip} private_ip=${master.private_ip}
%{endfor~}
EOF
    masters                = <<-EOF
%{for index, master in module.workload_cluster.master_ips~}
${local.prefix_wc}-${index}
%{endfor~}
EOF
    worker_hosts           = <<-EOF
%{for index, worker in module.workload_cluster.worker_ips~}
${local.prefix_wc}-${index} ansible_host=${worker.public_ip} private_ip=${worker.private_ip}
%{endfor~}
EOF
    workers                = <<-EOF
%{for index, worker in module.workload_cluster.worker_ips~}
${local.prefix_wc}-${index}
%{endfor~}
EOF
    control_plane_endpoint = module.workload_cluster.master_internal_loadbalancer_fqdn
    public_endpoint        = module.workload_cluster.master_external_loadbalancer_fqdn
    cluster_name           = local.prefix_wc
    cloud_provider         = "aws"
    cloud_config           = ""
    loadbalancers          = ""
    control_plane_port     = ""
  })
}
