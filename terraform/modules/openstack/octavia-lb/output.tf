output "floating_ips" {
  description = "List of floating ips."

  value = [openstack_networking_floatingip_v2.loadbalancer_lb_fip.address]
}

output "instance_ips" {
  description = "The private and public floating ip addresses of the loadbalancer."

  value = {
    (local.lb_name) = {
      "public_ip"  = openstack_networking_floatingip_v2.loadbalancer_lb_fip.address
      "private_ip" = openstack_lb_loadbalancer_v2.loadbalancer.vip_address
    }
  }
}
