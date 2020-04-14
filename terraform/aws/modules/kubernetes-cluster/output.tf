output "master_ips" {
  value = {
    for index, instance in aws_instance.master :
    index => {
      "public_ip" : instance.public_ip
      "private_ip" : instance.private_ip
    }
  }
}

output "worker_ips" {
  value = {
    for index, instance in aws_instance.worker :
    index => {
      "public_ip" : instance.public_ip
      "private_ip" : instance.private_ip
    }
  }
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
