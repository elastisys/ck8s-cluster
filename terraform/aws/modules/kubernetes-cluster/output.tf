output "master_public_ips" {
  value = [
    for instance in aws_instance.master: {
      "public_ip": instance.public_ip
    }
  ]
}

output "master_private_ips" {
  value = [
    for instance in aws_instance.master: {
      "private_ip": instance.private_ip
    }
  ]
}

output "worker_public_ips" {
  value = [
    for instance in aws_instance.worker: {
      "public_ip": instance.public_ip
    }
  ]
}

output "worker_private_ips" {
  value = [
    for instance in aws_instance.worker: {
      "private_ip": instance.private_ip
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
  value = aws_lb.master_lb_internal.dns_name
}

output "master_external_loadbalancer_fqdn" {
  value = aws_lb.master_lb_external.dns_name
}