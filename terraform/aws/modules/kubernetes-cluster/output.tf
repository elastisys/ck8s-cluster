output "master_ips" {
  value = [
    for instance in aws_instance.master : {
      "public_ip" : instance.public_ip
      "private_ip" : instance.private_ip
    }
  ]
}

output "worker_ips" {
  value = [
    for instance in aws_instance.worker : {
      "public_ip" : instance.public_ip
      "private_ip" : instance.private_ip
    }
  ]
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.main_sn.id
}

output "subnet_cidr_blocks" {
  value = aws_subnet.main_sn.cidr_block
}

output "master_internal_loadbalancer_fqdn" {
  value = aws_elb.master_lb_int.dns_name
}

output "master_external_loadbalancer_fqdn" {
  value = aws_elb.master_lb_ext.dns_name
}

output "ansible_inventory" {
  value = templatefile("${path.module}/../../../templates/inventory.tmpl", {
    master_hosts           = <<-EOF
%{for index, master in aws_instance.master~}
${var.prefix}-${index} ansible_host=${master.public_ip} private_ip=${master.private_ip}
%{endfor~}
EOF
    masters                = <<-EOF
%{for index, master in aws_instance.master~}
${var.prefix}-${index}
%{endfor~}
EOF
    worker_hosts           = <<-EOF
%{for index, worker in aws_instance.worker~}
${var.prefix}-${index} ansible_host=${worker.public_ip} private_ip=${worker.private_ip}
%{endfor~}
EOF
    workers                = <<-EOF
%{for index, worker in aws_instance.worker~}
${var.prefix}-${index}
%{endfor~}
EOF
    control_plane_endpoint = aws_elb.master_lb_int.dns_name
    public_endpoint        = aws_elb.master_lb_ext.dns_name
    cluster_name           = var.prefix
    cloud_provider         = "aws"
    cloud_config           = ""
    loadbalancers          = ""
  })
}
